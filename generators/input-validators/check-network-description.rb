#!/usr/bin/ruby

# This script checks the network description for inconsistencies

require 'json'
require 'pp'

# FIXME infiniband equipment is not completely described in the ref-api yet. See Bug 8586
HPC_SWITCHES = ['ib-grenoble', 'voltaire-1', 'voltaire-2', 'voltaire-3', 'sgraoullyib', 'sgrapheneib', 'sw-myrinet', 'sgrele-opf']

def check_network_description(options)
  ok = true
  puts "Documentation: https://www.grid5000.fr/mediawiki/index.php/TechTeam:Network_Description"
  options[:sites].each do |site|
    puts "Checking #{site}..."

    # get list of network equipments and nodes
    neteqs = []
    nodes = []
    Dir::glob("../../data/grid5000/sites/#{site}/network_equipments/*.json").each do |f|
      neteqs << JSON::parse(IO::read(f))
    end
    Dir::glob("../../data/grid5000/sites/#{site}/clusters/*/nodes/*.json").each do |f|
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
        netnodes << { 'kind' => 'node', 'uid' => n['uid'], 'port' => nic['device'], 'rate' => nic['rate'], 'switch' => nic['switch'], 'interface' => nic['interface'], 'mounted' => nic['mounted'], 'mountable' => nic['mountable'], 'nickname' => nic['network_address'].split('.')[0] }
      end
    end

    neteqs.each do |eq|
      netnodes << { 'kind' => eq['kind'], 'uid' => eq['uid'], 'nickname' => eq['uid'] }
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

    # scan equipments ports, search for each node
    neteqs.each do |eq|
      puts "looking at #{eq['uid']} ..."
      eq['linecards'].each do |lc|
        (lc['ports'] || []).each do |port|
          # skip if empty port
          next if port == {}

          #### FIXME toute cette partie pourrait être enlevée si les données étaient complètes dans l'API ...
          if port['kind'].nil?
            # aucun type de port (node, switch, etc.) n'est spécifié. Cherchons si on trouve un netnode (noeud ou switch) avec cet uid, et prenons sa seule interface 'mounted' pas Infiniband...
            mynetnodes = netnodes.select { |n| n.values_at('uid') == port.values_at('uid') and n['interface'] != 'InfiniBand' and n['interface'] != 'Myrinet' }
            if mynetnodes.length == 1
              # on n'en a trouvé qu'un seul, c'est donc forcément le bon
              mynetnodes.first['found'] += 1
              links << { 'nicknames' => [ eq['uid'], mynetnodes.first['nickname'] ].sort, 'switch' => eq['uid'], 'target' => mynetnodes.first['nickname'], 'rate' => port['rate'] || lc['rate'], 'target_node' => mynetnodes.first['uid'], 'port' => mynetnodes.first['port'] }
            elsif mynetnodes.length > 1
              # il y en a plusieurs...
              if port['port'].nil?
                # et pas de port précisé. C'est une erreur.
                puts "ERROR: port specification matches several network nodes. port=#{port} ; network nodes matched=#{mynetnodes}"
                ok = false
              else
                # mais un port est précisé, cherchons avec le port
                mynetnodes = netnodes.select { |n| n.values_at('uid', 'port') == port.values_at('uid', 'port') }
                if mynetnodes.length == 1
                  # on n'en a trouvé qu'un seul, c'est donc forcément le bon
                  mynetnodes.first['found'] += 1
                  links << { 'nicknames' => [ eq['uid'], mynetnodes.first['nickname'] ].sort, 'switch' => eq['uid'], 'target' => mynetnodes.first['nickname'], 'rate' => port['rate'] || lc['rate'], 'target_node' => mynetnodes.first['uid'], 'port' => mynetnodes.first['port'] }
                elsif mynetnodes.length > 1
                  puts "ERROR: port specification matches several network nodes. port=#{port} ; network nodes matched=#{mynetnodes}"
                  ok = false
                else # = 0
                  puts "ERROR: port specification matches no network nodes: #{port}"
                  ok = false
                end
              end
            else # = 0
              puts "ERROR: port specification matches no network nodes: #{port}"
              ok = false
            end
          elsif port['kind'] == 'node'
            if port['port'].nil?
              # aucun port (par ex eth0) n'est spécifié, on suppose que c'est la seule interface 'mounted' pour cet uid
              mynetnodes = netnodes.select { |n| n.values_at('kind', 'uid') == port.values_at('kind', 'uid') and n['mounted'] }
              if mynetnodes.length == 1
                # on n'en a trouvé qu'un seul, c'est donc forcément le bon
                mynetnodes.first['found'] += 1
                links << { 'nicknames' => [ eq['uid'], mynetnodes.first['nickname'] ].sort, 'switch' => eq['uid'], 'target' => mynetnodes.first['nickname'], 'rate' => port['rate'] || lc['rate'], 'target_node' => mynetnodes.first['uid'], 'port' => mynetnodes.first['port'] }
              elsif mynetnodes.length > 1
                puts "ERROR: port specification matches several network nodes. port=#{port} ; network nodes matched=#{mynetnodes}"
                ok = false
              else # = 0
                puts "ERROR: port specification matches no network nodes: #{port}"
                ok = false
              end
           ########### .... jusqu'à ici ! (fin du FIXME)
            else # port défini
              mynetnodes = netnodes.select { |n| n.values_at('kind', 'uid', 'port') == port.values_at('kind', 'uid', 'port') }
              if mynetnodes.length == 1
                mynetnodes.first['found'] += 1
                links << { 'nicknames' => [ eq['uid'], mynetnodes.first['nickname'] ].sort, 'switch' => eq['uid'], 'target' => mynetnodes.first['nickname'], 'rate' => port['rate'] || lc['rate'], 'target_node' => mynetnodes.first['uid'], 'port' => mynetnodes.first['port'] }
              else
                puts "ERROR: this port is connected to a node that does not exist: #{port}"
                ok = false
              end
            end
          elsif port['kind'] == 'switch' or port['kind'] == 'router'
            mynetnodes = netnodes.select { |n| n.values_at('kind', 'uid') == port.values_at('kind', 'uid') }
            if mynetnodes.length == 1
              mynetnodes.first['found'] += 1
              links << { 'nicknames' => [ eq['uid'], mynetnodes.first['nickname'] ].sort, 'switch' => eq['uid'], 'target' => mynetnodes.first['nickname'], 'rate' => port['rate'] || lc['rate'], 'target_node' => mynetnodes.first['uid'], 'port' => mynetnodes.first['port'] }
            else
              puts "ERROR: this port is connected to a switch or router that does not exist: #{port}"
              ok = false
            end
          elsif port['kind'] == 'other' or port['kind'] == 'virtual'
            puts "INFO: skipping port kind #{port['kind']} for #{port['uid']}"
          else
            puts "ERROR: unknown port kind: #{port}"
            ok = false
          end
        end
      end
    end

    # find netnodes without connection
    # for routers, it's OK, because they would be connected to other G5K routers
    netnodes.select { |n| n['found'] == 0 and not n['kind'] == 'router' }.each do |n|
      if n['interface'] == 'InfiniBand' or n['interface'] == 'Myrinet' or HPC_SWITCHES.include?(n['uid'])
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
  nodeslinks.map! { |e| e[1] = `echo #{e[1].uniq.join(' ')}|nodeset -f`.chomp ; e }

  fd = File::new("network_#{site}.dot", 'w')
  fd.puts "graph graphname {"
  router = mynetnodes.select { |n| n['kind'] == 'router' }.first['nickname']
  fd.puts <<-EOF
  root="#{router}";
  layout=twopi;
  overlap=scale;
  splines=true;
  ranksep=2.0;
        EOF
  # output graph nodes, equipment first
  (eqlinks.map { |e| e['switch'] } + eqlinks.map { |e| e['target'] }).each do |eq|
    fd.puts "\"#{eq}\" [shape=box];"
  end
  # then nodes groups
  nodeslinks.each do |e|
    fd.puts "\"#{e[1]}\";"
  end

  # finally output links
  # between network equipments
  eqlinks.each do |l|
    r = "#{l['rate'] / 10**9}G"
    fd.puts "\"#{l['switch']}\" -- \"#{l['target']}\" [label=\"#{r}\"];"
  end
  # between network equipments and nodes
  nodeslinks.each do |l|
    if l[0][1].length > 1
      # more than one interface, show port number
      l[0][1].to_a.sort { |a, b| a[0] <=> b[0] }.each do |e|
        iface, target = e
        iface = iface.gsub('eth', '')
        r = "#{target['rate'] / 10**9}G"
        fd.puts "\"#{target['switch']}\" -- \"#{l[1]}\" [label=\"#{r}\",headlabel=\"#{iface}\"];"
      end
    else
      # only one interface
      l[0][1].each_pair do |iface, target|
        r = "#{target['rate'] / 10**9}G"
        fd.puts "\"#{target['switch']}\" -- \"#{l[1]}\" [label=\"#{r}\",len=2.0];"
      end
    end
  end
  fd.puts "}"
  fd.close
  system("dot -Tpdf network_#{site}.dot -onetwork_#{site}.pdf")
  system("dot -Tpng network_#{site}.dot -onetwork_#{site}.png")
end


if __FILE__ == $0
  require 'optparse'

  options = {}
  options[:sites] = %w{grenoble lille luxembourg lyon nancy nantes rennes sophia}

  OptionParser.new do |opts|
    opts.banner = "Usage: check-network-description.rb [options]"

    opts.separator ""
    opts.separator "Example: ruby check-network-description.rb -v"

    ###

    opts.separator ""
    opts.separator "Filters:"

    opts.on('-s', '--sites a,b,c', Array, 'Select site(s)',
            "Default: "+options[:sites].join(", ")) do |s|
      raise "Wrong argument for -s option." unless (s - options[:sites]).empty?
      options[:sites] = s
    end

    opts.separator ""
    opts.separator "Common options:"

    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      options[:verbose] ||= 0
      options[:verbose] = options[:verbose] + 1
    end

    opts.on("", "--dot", "Generate one dotfile per site") do
      options[:dot] = true
    end

    # Print an options summary.
    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end.parse!

  exit(check_network_description(options))
end
