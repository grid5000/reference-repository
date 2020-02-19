# coding: utf-8

# This script checks the network description for inconsistencies
# This script needs 'nodeset' and 'dot' programs, which are available
# in clustershell and graphviz debian packages

# FIXME infiniband equipment is not completely described in the ref-api yet. See Bug 8586
HPC_SWITCHES = ['ib-grenoble', 'voltaire-1', 'voltaire-2', 'voltaire-3', 'sgraoullyib', 'sw-myrinet', 'sgrele-opf']

def check_network_description(options)
  ok = true
  puts "Documentation: https://www.grid5000.fr/mediawiki/index.php/TechTeam:Network_Description"
  options[:sites].each do |site|
    puts "Checking #{site}..."

    # get list of network equipments and nodes
    neteqs = []
    nodes = []
    Dir::glob("data/grid5000/sites/#{site}/network_equipments/*.json").each do |f|
      neteqs << JSON::parse(IO::read(f))
    end
    Dir::glob("data/grid5000/sites/#{site}/clusters/*/nodes/*.json").each do |f|
      nodes << JSON::parse(IO::read(f))
    end

    # get list of netnodes (possible network endpoints)
    netnodes = []
    nodes.each do |n|
      n['network_adapters'].each do |nic|
        next if not (nic['mounted'] or nic['mountable'])
        if nic['network_address'].nil?
          puts "ERROR: this interface doesn't have a network_address: #{nic}"
          ok = false
          nic['network_address'] = "#{n['uid']}-#{nic['device']}.#{site}.grid5000.fr" # hack
        end
        netnodes << {
          'kind' => 'node',
          'uid' => n['uid'],
          'port' => nic['device'],
          'rate' => nic['rate'],
          'switch' => nic['switch'],
          'interface' => nic['interface'],
          'mounted' => nic['mounted'],
          'mountable' => nic['mountable'],
          'nickname' => nic['network_address'].split('.')[0]
        }
      end
    end

    neteqs.each do |eq|
      netnodes << {
        'kind' => eq['kind'],
        'uid' => eq['uid'],
        'nickname' => eq['uid']
      }
    end

    # check number of routers
    routers = netnodes.select { |e| e['kind'] == 'router' }
    if routers.length != 1
      puts "ERROR: Number of routers different from 1: #{routers.length}"
      ok = false
      pp routers
    end

    # initialize found attribute to 0
    netnodes.each do |nn|
      nn['found'] = 0
    end

    dupes = netnodes.select { |e| netnodes.count(e) > 1 }
    if dupes.length > 0
      puts "ERROR: duplicate 'nickname' values in network hosts"
      ok = false
    end

    links = []

    # scan neteq for backplane_bps (bug 8294)
    puts "Scanning network equipments for backplane_bps..."
    neteqs.each do |eq|
      next if HPC_SWITCHES.include?(eq['uid'])
      puts "looking at #{eq['uid']} ..."
      if not eq['backplane_bps']
        puts "WARNING: #{eq['uid']} has no backplane_bps"
      end
      if eq['linecards'].length > 1 # only look at LC-specific backplane if switch has more than one linecard
        eq['linecards'].each do |lc|
          next if lc.keys.empty?
          if not lc['backplane_bps']
            puts "WARNING: #{eq['uid']} has a linecard without backplane_bps"
          end
        end
      end
    end

    # scan equipments ports, search for each node
    neteqs.each do |eq|
      puts "looking at #{eq['uid']} ..."
      if HPC_SWITCHES.include?(eq['uid'])
        puts "This is an HPC switch. ERRORs will be non-fatal."
        oldok = ok
      end
      eq['linecards'].each_with_index do |lc, lc_i|
        (lc['ports'] || []).each_with_index do |port, port_i|
          # skip if empty port
          next if port == {}

          if port['kind'] == 'node'
            mynetnodes = netnodes.select { |n| n.values_at('kind', 'uid', 'port') == port.values_at('kind', 'uid', 'port') }
            if mynetnodes.length == 1
              mynetnodes.first['found'] += 1
              links << {
                'nicknames' => [ eq['uid'], mynetnodes.first['nickname'] ].sort,
                'switch' => eq['uid'],
                'target' => mynetnodes.first['nickname'],
                'rate' => port['rate'] || lc['rate'],
                'target_node' => mynetnodes.first['uid'],
                'port' => mynetnodes.first['port']
              }
            else
              puts "ERROR: this port is connected to a node that does not exist: #{port}"
              ok = false
            end
          elsif ['switch','router'].include?(port['kind'])
            mynetnodes = netnodes.select { |n| n.values_at('kind', 'uid') == port.values_at('kind', 'uid') }
            if mynetnodes.length == 1
              mynetnodes.first['found'] += 1
              links << {
                'nicknames' => [ eq['uid'], mynetnodes.first['nickname'] ].sort,
                'switch' => eq['uid'],
                'target' => mynetnodes.first['nickname'],
                'rate' => port['rate'] || lc['rate'],
                'target_node' => mynetnodes.first['uid'],
                'port' => mynetnodes.first['port']
              }
            else
              puts "ERROR: this port is connected to a switch or router that does not exist: #{port}"
              ok = false
            end
          elsif ['other','virtual','server','backbone'].include?(port['kind'])
            puts "INFO: skipping port kind #{port['kind']} for #{port['uid']}"
          elsif port['kind'] == 'channel'

            # Check that the port of kind channel is reference in channels
            port_to_lookup = port['snmp_name']
            channel = eq['channels'][port['uid']]
            unless channel
              puts "ERROR: port #{port_to_lookup} is referencing a channel that doesn't exist on #{eq['uid']}"
              ok = false
            end

            if channel && ['server','other'].include?(channel['kind'])
              puts "INFO: skipping channel for #{channel['kind']} #{port['uid']}"
            elsif channel && ['switch','router'].include?(channel['kind'])

              channel_ports = eq['linecards'].reject { |i| i == {} }.map do |i|
                i['ports'].reject { |j| j == {} }
                  .select { |k| k['uid'] == port['uid'] }
              end.reject { |i| i == [] }.first

              # Check that port of kind channel is referencing a port of type channel
              # only if the channel is connected to router/switch
              connected_to = neteqs.select { |n| n['uid'] == channel['uid'] }.first

              unless connected_to && connected_to['channels'][channel['port']]
                puts "ERROR #{channel['port']} not found on #{channel['uid']}"
                ok = false
                next
              end

              connected_to = connected_to['linecards'].reject { |i| i == {} }.map do |i|
                i['ports'].reject { |j| j == {} }
                  .select { |k| k['uid'] == channel['port'] }
              end.reject { |i| i == [] }.first

              if connected_to.length == 0
                puts "ERROR: port #{port_to_lookup} on #{eq['uid']} is not connected to an endpoint"
                ok = false
              elsif connected_to.length == 1
                puts "ERROR: port #{port_to_lookup} is a channel on #{eq['uid']} and is only connected to one endpoint"
                pp connected_to
                ok = false
              elsif connected_to.length != channel_ports.length
                puts "ERROR: channel misconfiguration for #{port_to_lookup} on #{eq['uid']} with #{port['uid']} "
                ok = false
              else
                mynetnodes = netnodes.select { |n| n['uid'] == channel['uid'] }
                mynetnodes.first['found'] += 1
                links << {
                  'nicknames' => [ eq['uid'], channel['uid'] ].sort,
                  'switch' => eq['uid'],
                  'target' => channel['uid'],
                  'rate' => port['rate'] || lc['rate'],
                  'target_node' => channel['uid'],
                  'port' => mynetnodes.first['port']
                }
              end
            end
          else
            puts "ERROR: unknown port kind: #{port}"
            ok = false
          end
        end
      end
      if HPC_SWITCHES.include?(eq['uid'])
        ok = oldok
      end
    end

    neteqs.each do |eq|
      next if eq['channels'].nil?

      eq['channels'].each do |k,v|
        # Check that channel is referencing a correct channel
        # only if the channel is connected to router/switch
        next unless ['switch', 'router'].include?(v['kind'])
        c_lookup = neteqs.select { |n| n['uid'] == v['uid'] }
        c_lookup = c_lookup.length.zero? ? nil : c_lookup.first['channels']

        if !c_lookup.nil? and !c_lookup[v['port']].nil? and
            c_lookup[v['port']]['port'] != k
          puts "ERROR: channel #{k} of #{eq['uid']} not found on #{v['uid']} found #{c_lookup[v['port']]['port']} instead"
          ok =false
        end
      end
    end

    # find netnodes without connection
    # for routers, it's OK, because they would be connected to other G5K routers
    netnodes.select { |n| n['found'] == 0 and not n['kind'] == 'router' }.each do |n|
      if n['interface'] == 'InfiniBand' or n['interface'] == 'Myrinet' or n['interface'] == 'Omni-Path' or HPC_SWITCHES.include?(n['uid'])
        puts "WARNING: we did not find a corresponding entry on a network equipment for this InfiniBand node: #{n}"
      else
        puts "ERROR: we did not find a corresponding entry on a network equipment for this node or equipment (where is it plugged?!): #{n}"
        ok = false
      end
    end

    # find netnodes with more than one connection
    netnodes.select { |n| n['found'] > 1 }.each do |n|
      next if ['router', 'switch'].include?(n['kind']) # routers and switches might be connected several times, that's OK
      puts "ERROR: this network node is connected to more than one switch port: #{n}"
      ok = false
    end

    linknicks = links.map { |l| l['nicknames'] }
    linknicks.uniq.each do |l|
      n0 = netnodes.select { |n| n['nickname'] == l[0] }.first
      n1 = netnodes.select { |n| n['nickname'] == l[1] }.first
      if ['router','switch'].include?(n0['kind']) and ['router','switch'].include?(n1['kind'])
        next if HPC_SWITCHES.include?(n0['nickname']) or HPC_SWITCHES.include?(n1['nickname']) # FIXME we ignore problems with HPC switches for now
        # this is a link between network equipment
        if linknicks.count(l) % 2 != 0
          puts "ERROR: link between two network equipments should have 2 instances (or 4, 6, 8 in case of aggregation) (probably switch A is connected to switch B, but B is not connected to A): #{l} (actual count: #{linknicks.count(l)})"
          ok = false
        end
      else
        if linknicks.count(l) != 1
          puts "ERROR: duplicate link : #{l} (actual count: #{linknicks.count(l)})"
          ok = false
        end
      end
    end

    links.each do |l|
      nn = netnodes.select { |n| n['nickname'] == l['target'] }.first
      next if nn['kind'] != 'node'
      if l['rate'] != nn['rate']
        puts "ERROR: invalid rate for #{l}: netnode has #{l['rate']}"
        ok = false
      end
    end

    if options[:dot]
      generate_dot(netnodes, links, site)
    end
  end
  return ok
end

def generate_dot(netnodes, links, site)
  mynetnodes = []
  netnodes.each do |n|
    next if n['interface'] == 'InfiniBand' or n['interface'] == 'Myrinet' or HPC_SWITCHES.include?(n['nickname'])
    mynetnodes << n
  end
  # delete nodes we don't care about (HPC networks)
  nicknames = mynetnodes.map { |n| n['nickname'] }
  links.delete_if { |l| not (nicknames.include?(l['switch']) and nicknames.include?(l['target'])) }

  # enrich links
  links.each do |l|
    nn = mynetnodes.select { |n| n['nickname'] == l['target'] }.first
    l['target_kind'] = nn['kind']
    if l['target_kind'] == 'node'
      l['target_cluster'] = l['target'].split('-')[0]
    end
  end

  # remove duplicate reverse links between switches. We keep only the one where the target is the second node.
  links.delete_if { |l| ['router', 'switch'].include?(l['target_kind']) and l['target'] == l['nicknames'].first }

  # separate links to equipments
  eqlinks = links.select { |l| ['router', 'switch'].include?(l['target_kind']) }
  # group links between same pairs of switches
  eqlinks = eqlinks.group_by { |e| e }.to_a.map { |e| e[0]['count'] = e[1].length ; e[0] }
  # for links to nodes, re-process the links to facilitate grouping
  nodeslinks = []
  links.select { |l| ['node'].include?(l['target_kind']) }.each do |l|
    mynodelinks = nodeslinks.select { |nl| l['target_node'] == nl['target_node'] }.first
    if mynodelinks.nil?
      mynodelinks = { 'target_cluster' => l['target_cluster'], 'target_node' => l['target_node'], 'attachments' => {} }
      nodeslinks << mynodelinks
    end
    mynodelinks['attachments'][l['port']] = { 'switch' => l['switch'], 'rate' => l['rate'] }
  end
  # group
  nodeslinks = nodeslinks.group_by { |l| [ l['target_cluster'], l['attachments'] ] }.to_a.map { |e| e[1].map! { |f| f['target_node'] } ; e }
  # factor
  nodeslinks.map! { |e| e[1] = sh("echo #{e[1].uniq.join(' ')}|nodeset -f"); e }

  header = []
  content = []
  trailer = []

  header << "graph graphname {"
  router = mynetnodes.select { |n| n['kind'] == 'router' }.first['nickname']
  header << "root=\"#{router}\";"
  header << "layout=twopi;"
  header << "overlap=scale;"
  if %w{sophia}.include?(site)
    header << "splines=false;"
  else
    header << "splines=true;"
  end
  header << "ranksep=2.0;"
  # output graph nodes, equipment first
  mynetnodes.select { |n| n['kind'] == 'router' or n['kind'] == 'switch' }.map { |e| e['uid'] }.sort.each do |eq|
    content << "\"#{eq}\" [shape=box color=\"gold\" style=\"filled\"];"
  end
  # then nodes groups
  nodeslinks.each do |e|
    content << "\"#{e[1]}\" [color=\"chartreuse2\" style=\"filled\"];"
  end

  # finally output links
  # between network equipments
  eqlinks.each do |l|
    if l['count'] == 1
      r = "#{l['rate'] / 10**9}G"
    else
      r = "#{l['count']}x#{l['rate'] / 10**9}G"
    end
    content << "\"#{l['switch']}\" -- \"#{l['target']}\" [label=\"#{r}\"];"
  end
  # between network equipments and nodes
  nodeslinks.each do |l|
    if l[0][1].length > 1
      # more than one interface, show port number
      l[0][1].to_a.sort { |a, b| a[0] <=> b[0] }.each do |e|
        iface, target = e
        iface = iface.gsub('eth', '')
        r = "#{target['rate'] / 10**9}G"
        content << "\"#{target['switch']}\" -- \"#{l[1]}\" [label=\"#{r}\",headlabel=\"#{iface}\"];"
      end
    else
      # only one interface
      l[0][1].each_pair do |iface, target|
        r = "#{target['rate'] / 10**9}G"
        content << "\"#{target['switch']}\" -- \"#{l[1]}\" [label=\"#{r}\",len=2.0];"
      end
    end
  end
  trailer << "}"

  name = "#{site.capitalize}Network"
  data = [header, content.sort, trailer].flatten.join("\n")
  IO.write("#{name}.dot", data)
  sh("dot -Tpdf #{name}.dot -o#{name}.pdf")
  sh("dot -Tpng #{name}.dot -o#{name}.png")
end

def sh(cmd)
  begin
    output = `#{cmd}`.chomp
  rescue StandardError => e
    raise "ERROR: The following command produced an error: #{cmd}\n#{e}" if $?.exitstatus != 0
  end
  return output
end
