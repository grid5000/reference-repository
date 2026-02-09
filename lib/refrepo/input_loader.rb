# Load a hierarchy of YAML file into a Ruby hash

require 'ipaddress'
require 'refrepo/hash/hash'
require 'refrepo/gen/reference-api'
require 'refrepo/gpu_ref'

def load_yaml_file_hierarchy(directory = File.expand_path('../../input/grid5000/', File.dirname(__FILE__)))
  global_hash = {} # the global data structure

  Dir.chdir(directory) do
    # Recursively list the .yaml files.
    # The order in which the results are returned depends on the system (http://ruby-doc.org/core-2.2.3/Dir.html).
    # => List deepest files first as they have lowest priority when hash keys are duplicated.
    list_of_yaml_files = Dir['**/*.y*ml', '**/*.y*ml.erb'].sort_by { |x| -x.count('/') }

    load_args = {}
    if ::Gem::Version.new(RUBY_VERSION) >= ::Gem::Version.new('3.1.0')
      # Fix compatibility with ruby 3.1
      load_args[:permitted_classes] = [Date, Time]
      load_args[:aliases] = true
    end

    list_of_yaml_files.each do |filename|
      begin
        # Load YAML
        file_hash = if /\.y.*ml\.erb$/.match(filename)
                      # For files with .erb.yaml extensions, process the template before loading the YAML.
                      YAML.load(ERB.new(File.read(filename)).result(binding), **load_args)
                    else
                      YAML.load_file(filename, **load_args)
                    end
        raise StandardError.new('loaded hash is empty') unless file_hash
      # YAML::Psych raises an exception if the file cannot be loaded.
      rescue StandardError => e
        puts "Error loading '#{filename}', #{e.message}"
      end

      # Inject the file content into the global_hash, at the right place
      path_hierarchy = File.dirname(filename).split('/')     # Split the file path (path relative to input/)
      path_hierarchy = [] if path_hierarchy == ['.']

      file_hash = Hash.from_array(path_hierarchy, file_hash) # Build the nested hash hierarchy according to the file path
      global_hash = global_hash.deep_merge(file_hash)        # Merge global_hash and file_hash. The value for entries with duplicate keys will be that of file_hash

      # Expand the hash. Done at each iteration for enforcing priorities between duplicate entries:
      # ie. keys to be expanded have lowest priority on existing entries but higher priority on the entries found in the next files
      global_hash.expand_square_brackets(file_hash)
    end
  end

  detect_dead_nodes_with_yaml_files(global_hash)

  # add switch and port to nodes
  add_switch_port(global_hash)

  # populate each node with its IPv4 addresses
  add_ipv4(global_hash)

  # add some ipv6 informations in sites
  add_site_ipv6_infos(global_hash)

  # populate each node with its IPv6
  add_ipv6(global_hash)

  # populate each node with its kavlan IPs
  add_kavlan_ips(global_hash)
  add_kavlan_ipv6s(global_hash)

  # populate each node with software informations
  add_software(global_hash)

  # populate each node with theorical flops
  add_theorical_flops(global_hash)

  # add GPU information from GPURef
  add_gpu_information(global_hash)

  # populate each node with administration tools' parameters
  add_management_tools(global_hash)

  # surround call to add_default_values_and_mappings() with
  # add_tmp_kavlanng_adapters() and
  # clean_tmp_kavlanng_adapters(). These functions create a temporary
  # kavlanng hash in nodes, mapping each network interface to a
  # boolean, meaning which network interfaces has kalvanng enabled. It
  # is then used in add_default_values_and_mappings() to set the
  # boolean kavlanng property of the interface, only if needed (only
  # if is different from the kavlan property). This code is temporary
  # (September 15, 2025), only needed for the time period where we
  # have both kavlan and kavlanng running in parallel, and we want
  # some specific clusers to be enabled for kavlanng, and not for
  # kavlan (or the opposite).
  add_tmp_kavlanng_adapters(global_hash)

  add_default_values_and_mappings(global_hash)

  # see 5 lines above
  clean_tmp_kavlanng_adapters(global_hash)

  add_node_pdu_mapping(global_hash)

  add_wattmetre_mapping(global_hash)

  add_generic_metrics(global_hash)

  # populate each cluster with metrics network information
  add_network_metrics(global_hash)

  # populate each cluster with metrics PDU information
  add_pdu_metrics(global_hash)

  complete_network_equipments(global_hash)

  global_hash
end

def add_node_pdu_mapping(h)
  h['sites'].each do |site_uid, site|
    site.fetch('pdus', []).each do |pdu_uid, pdu|
      # Get pdu information from node description in clusters/ hierachy
      pdu_attached_nodes = {}
      site.fetch('clusters', []).sort.each do |_cluster_uid, cluster|
        cluster['nodes'].each do |node_uid, node| # _sort_by_node_uid
          next if node['status'] == 'retired'

          node.fetch('pdu', []).each do |node_pdu|
            pdu_attached_nodes[node_pdu['port']] = node_uid if node_pdu['uid'] == pdu_uid
          end
        end
      end

      # Merge pdu information from pdus/ hierachy into node information
      pdu.fetch('ports', {}).each do |port_uid, nodes_uid|
        nodes_uid = nodes_uid['uid'] if nodes_uid.is_a?(Hash)
        nodes_uid = [nodes_uid] if nodes_uid.is_a?(String)
        nodes_uid.each do |node_uid|
          node = site['clusters'].fetch(node_uid.split('-')[0], {}).fetch('nodes', {}).fetch(node_uid, nil)
          next unless node

          node['pdu'] ||= []
          if node['pdu'].any? { |p| p['uid'] == pdu_uid && p['port'] == port_uid }
            raise "ERROR: Node #{node_uid}.#{site_uid} has PDU #{pdu_uid} description defined both in clusters/ and pdus/ hierarchy"
          end

          node['pdu'].append({ 'uid' => pdu_uid, 'port' => port_uid })
        end
      end

      # Merge pdu information from node description in pdus/ hierachy
      pdu_attached_nodes.each do |port_uid, node_uid|
        if pdu.fetch('ports', {}).key?(port_uid)
          raise "ERROR: Port #{port_uid} of #{pdu_uid}.#{site_uid} is defined both in PDU description and in node #{node_uid} description"
        end

        pdu['ports'] ||= {}
        if !pdu['ports'].key?(port_uid)
          pdu['ports'][port_uid] = node_uid
        elsif pdu['ports'].key?(port_uid) and pdu['ports']['port_uid'].is_a?(String)
          pdu['ports'][port_uid] = [pdu['ports'][port_uid], node_uid]
        else
          pdu['ports'][port_uid].append(node_uid)
        end
      end
    end
  end
end

def add_wattmetre_mapping(h)
  h['sites'].each do |site_uid, site|
    site.fetch('pdus', []).each do |pdu_uid, pdu|
      # Process wattmetre v3 information from pdus/ hierachy
      next unless pdu_uid.include?('wattmetrev3') # TODO: better way of identifying a V3 wattmetre

      wattmetre_modules = {}
      wattmetre_modules[pdu['serial'].to_i] = {} if pdu.fetch('master_monitoring', false)
      # Look for other PDUs where this wattmetre is used
      site.fetch('pdus', []).each do |_other_pdu_uid, other_pdu|
        other_pdu.fetch('ports', {}).each do |other_port_uid, other_port_data|
          next unless other_port_data.is_a?(Hash)
          next if other_port_data['wattmetre'] != pdu_uid

          mod = other_port_data['module'].to_i
          chan = other_port_data['channel'].to_i
          node_uid = other_port_data['uid']
          wattmetre_modules[mod] = {} unless wattmetre_modules[mod]
          wattmetre_modules[mod][chan] = node_uid
          # Convert PDU port's full Hash to string w/ node uid for generated data
          other_pdu['ports'][other_port_uid] = node_uid
        end
      end
      # Wattmetre ports are numbered by modules serial, then by channels inside module
      wattmetre_modules.sort.each_with_index do |m, module_idx|
        channels = m[1]
        channels.sort.sort.each_with_index do |c, _chan_idx|
          node_uid = c[1]
          # Each module has 6 channels
          port_num = module_idx * 6 + c[0] - 1

          pdu['ports'] ||= {}
          if pdu['ports'].key?(port_num)
            raise "ERROR: Port #{port_num} of #{pdu_uid}.#{site_uid} is defined both in wattmetre description and in other PDUs' port info"
          end

          # Add mapping to wattmetre description under pdus/ hierarchy
          pdu['ports'][port_num] = node_uid

          # Add mapping to node description under clusters/ hierarchy
          nodes_uid = node_uid.is_a?(String) ? [node_uid] : node_uid
          nodes_uid.each do |nnode_uid|
            node = site['clusters'].fetch(nnode_uid.split('-')[0], {}).fetch('nodes', {}).fetch(nnode_uid, nil)
            node['pdu'] ||= []
            if node['pdu'].any? { |p| p['uid'] == pdu_uid && p['port'] == port_num }
              raise "ERROR: Node #{nnode_uid}.#{site_uid} has PDU #{pdu_num} description defined both in clusters/ and pdus/ hierarchy"
            end

            node['pdu'].append({ 'uid' => pdu_uid, 'port' => port_num, 'kind' => 'wattmetre-only' })
          end
        end
      end
    end
  end
end

def add_default_values_and_mappings(h)
  h['sites'].each do |site_uid, site|
    site.fetch('pdus', []).each do |pdu_uid, pdu|
      pdu['type'] = 'pdu'
      pdu['uid']  = pdu_uid
    end

    site.fetch('sensors', []).each do |sensor_uid, sensor|
      sensor['type'] = 'sensor'
      sensor['uid']  = sensor_uid
    end

    site.fetch('servers', []).each do |server_uid, server|
      server['type'] = 'server'
      server['uid'] = server_uid
      if server['kind'] == 'physical'
        server['redfish'] = server.key?('redfish') ? server['redfish'] : true
      end
    end

    site.fetch('clusters', []).sort.each do |cluster_uid, cluster|
      #
      # Write cluster info
      #

      cluster['type'] = 'cluster'
      cluster['uid']  = cluster_uid
      cluster['exotic'] = cluster.key?('exotic') ? cluster['exotic'] : false
      cluster['redfish'] = cluster.key?('redfish') ? cluster['redfish'] : true

      # On the previous version of this script, cluster["created_ad"] was generated from a Ruby Time. cluster["created_ad"] is now a Ruby Date at JSON import.
      # As Date.httpdate and Time.httpdate does not behave the same with timezone, it is converted here as a Ruby time.
      cluster['created_at'] = Date.parse(cluster['created_at'].to_s).httpdate

      #
      # Write node info
      #

      cluster['nodes'].each do |node_uid, node| # _sort_by_node_uid
        # puts node_uid

        node['uid'] = node_uid
        node['type'] = 'node'
        node['processor']['cache_l1'] ||= nil if node.key?('processor')

        # Add default keys
        node['main_memory'] = {} unless node.key?('main_memory')

        node['exotic'] = cluster.key?('exotic') ? cluster['exotic'] : false unless node.key?('exotic')
        node['redfish'] = cluster.key?('redfish') ? cluster['redfish'] : true

        node['supported_job_types']['queues'] = cluster['queues'] unless node['supported_job_types'].key?('queues')

        # Delete keys
        # raise 'node["storage_devices"] is nil' if node["storage_devices"].nil?
        Hash(node['storage_devices']).keys.each do |key|
          node['storage_devices'][key].delete('timeread')  if node['storage_devices'][key].key?('timeread')
          node['storage_devices'][key].delete('timewrite') if node['storage_devices'][key].key?('timewrite')
        end

        # Ensure that id (diskN) is present
        node['storage_devices'].each do |key, hash|
          raise "Missing id for disk #{key} from cluster input (node=#{node_uid}, hash=#{hash})" unless hash['id']
        end

        # Add vendor info to storage
        node['storage_devices'].each do |key, hash|
          next if node['status'] == 'retired' # we do not bother for retired nodes

          matching_vendor = {}
          matching_interface = []
          h['disk_vendor_model_mapping'].each do |interface, vendor|
            vendor.select do |k, v|
              matching_vendor[k] = v if v.include? hash['model']
              matching_interface << interface if v.include? hash['model']
            end
          end

          if matching_vendor.empty?
            raise "Model \"#{hash['model']}\" don't match any vendor in input/grid5000/disks.yaml"
          end
          if matching_vendor.length > 1
            raise "Model \"#{hash['model']}\" specify in multiple vendors: #{matching_vendor.keys} in input/grid5000/disks.yaml"
          end

          if !(hash['model'] == 'unknown') && (matching_interface.length > 1)
            raise "Model \"#{hash['model']}\" specify in multiple interface: #{matching_interface} in input/grid5000/disks.yaml"
          end

          hash['vendor'] = matching_vendor.keys.first

          if matching_interface.first != 'RAID' && hash['interface'] != matching_interface.first
            raise "Interface \"#{hash['interface']}\" for disk #{key} (model #{hash['model']}) does not match interface \"#{matching_interface.first}\" in input/grid5000/disks.yaml"
          end
        end

        # Ensure that by_id is present (bug 11043)
        node['storage_devices'].each do |_key, hash|
          hash['by_id'] = '' unless hash['by_id']
        end

        # Type conversion
        node['network_adapters'].each { |_key, hash| hash['rate'] = hash['rate'].to_i if hash['rate'].is_a?(Float) }

        # For each network adapters, populate "network_address", "switch" and "switch_port" from the network equipment description
        node['network_adapters'].each_pair do |device, network_adapter|
          network_adapter['mac'] = network_adapter['mac'].downcase if network_adapter['mac'].is_a?(String)

          # infiniband properties
          if network_adapter.key?('line_card')
            network_adapter['ib_switch_card']     =
              network_adapter.delete('line_card')
          end
          if network_adapter.key?('position')
            network_adapter['ib_switch_card_pos'] =
              network_adapter.delete('position')
          end

          if network_adapter['management']
            # Management network_adapter (bmc)
            unless network_adapter.key?('network_address')
              network_adapter['network_address'] =
                "#{node_uid}-bmc.#{site_uid}.grid5000.fr"
            end
          elsif network_adapter['mounted'] and /^eth[0-9]$/.match(device)
            # Primary network_adapter
            network_adapter['network_address'] = "#{node_uid}.#{site_uid}.grid5000.fr" if network_adapter['enabled']
          elsif network_adapter['mountable'] && !network_adapter.key?('network_address')
            # Secondary network_adapter(s)
            network_adapter['network_address'] =
              "#{node_uid}-#{device}.#{site_uid}.grid5000.fr"
          end
          # If kavlan entry is not defined here, set it node's kavlan description
          unless network_adapter['kavlan']
            network_adapter['kavlan'] = if node['kavlan'].nil?
                                          false
                                        else
                                          node['kavlan'].keys.include?(device) || false
                                        end
          end

          # compute if kavlanng has to be enabled or disabled on the
          # interface. Only if different from kavlan, explicitely set
          # it
          enable_kavlanng = if network_adapter.key?('kavlanng')
                              network_adapter['kavlanng']
                            elsif cluster.key?('kavlanng') && node.key?('kavlanng')
                              cluster['kavlanng'] && node['kavlanng'].keys.include?(device)
                            else
                              network_adapter['kavlan']
                            end
          if enable_kavlanng != network_adapter['kavlan']
            network_adapter['kavlanng'] = enable_kavlanng
          else
            network_adapter.delete('kavlanng')
          end

          network_adapter.delete('network_address') if network_adapter['network_address'] == 'none'
        end

        next unless node.key?('pdu')

        node['pdu'].each do |p|
          pdu = [p].flatten
          pdu.each do |item|
            # See https://intranet.grid5000.fr/bugzilla/show_bug.cgi?id=7585, workaround to validate node pdu that have per_outlets = false
            item.delete('port') if item['port'] == 'disabled'
          end
        end
        # node.key?("pdu")
      end
    end
  end
end

def sorted_vlan_offsets
  offsets = load_yaml_file_hierarchy['vlans']['offsets'].split("\n")
                                                        .map do |l|
    l = l.split(/\s+/)
    (4..7).each { |e| l[e] = l[e].to_i }
    l
  end
  # for local VLANs, we include the site when we sort
  puts offsets.select { |l| l[0] == 'local' }
              .sort_by { |l| [l[0], l[1]] + l[4..-1] }
              .map { |l| l.join(' ') }
              .join("\n")
  puts offsets.select { |l| l[0] != 'local' }
              .sort_by { |l| [l[0]] + l[4..-1] }
              .map { |l| l.join(' ') }
              .join("\n")
end

# Parse network equipment description and return switch name and port connected to given node
#  In the network description, if the node interface is given (using "port" attribute),
#  the interface parameter must be used.
def net_switch_port_lookup(site, node_uid, interface = '')
  site['networks'].each do |switch_uid, switch|
    switch['linecards'].each do |lc_uid, lc|
      lc['ports'].each do |port_uid, port|
        if port.is_a?(Hash)
          switch_remote_port = port['port'] || lc['port'] || ''
          switch_remote_uid = port['uid']
        else
          switch_remote_port = lc['port'] || ''
          switch_remote_uid = port
        end
        if switch_remote_uid =~ /([a-z]+[0-9]*-[0-9]*)-(.*)/
          n, p = switch_remote_uid.match(/([a-z]+[0-9]*-[0-9]*)-(.*)/).captures
          switch_remote_uid = n
          switch_remote_port = p
        end
        next unless switch_remote_uid == node_uid and switch_remote_port == interface

        # Build port name from snmp_naming_pattern
        # Example: '3 2 GigabitEthernet%LINECARD%/%PORT%' -> 'GigabitEthernet3/2'
        pattern = port['snmp_pattern'] || lc['snmp_pattern'] || ''
        port_name = pattern.sub('%LINECARD%', lc_uid.to_s).sub('%PORT%', port_uid.to_s)
        return switch_uid, port_name
      end
    end
  end
  nil
end

def add_switch_port(h)
  h['sites'].each_pair do |_site_uid, site|
    used_ports = {}
    site.fetch('clusters', {}).each_pair do |_cluster_uid, hc|
      hc['nodes'].each_pair do |node_uid, hn|
        next if hn['status'] == 'retired'
        raise "#{node_uid} has no network interfaces!" if hn['network_adapters'].nil?

        hn['network_adapters'].each_pair do |iface_uid, iface|
          unless (iface['mounted'] or iface['mountable']) and !iface['management'] and iface['interface'] =~ /(fpga|Ethernet)/
            next
          end

          switch, swport = net_switch_port_lookup(site, node_uid, iface_uid) || net_switch_port_lookup(site, node_uid)
          if !switch.nil? && !swport.nil? && used_ports[[switch, swport]]
            raise "Duplicate port assigned for #{node_uid} #{iface_uid}. Already assigned to #{used_ports[[switch,
                                                                                                           swport]]} Aborting."
          end

          used_ports[[switch, swport]] = [node_uid, iface_uid]
          iface['switch'] = switch
          iface['switch_port'] = swport
        end
      end
    end
  end
end

def detect_dead_nodes_with_yaml_files(h)
  h['sites'].each_pair do |site_uid, hs|
    hs.fetch('clusters', {}).each_pair do |cluster_uid, hc|
      hc['nodes'].each_pair do |node_uid, hn|
        next unless hn['status'] == 'retired'
        if File.exist?("input/grid5000/sites/#{site_uid}/clusters/#{cluster_uid}/nodes/#{node_uid}.yaml")
          raise "ERROR: #{node_uid} is marked status:retired, but its yaml is still in the repository. Please remove it."
        end
      end
    end
  end
end

def add_kavlan_ips(h)
  allocated = {}
  vlan_base = h['vlans']['base']
  vlan_offset = h['vlans']['offsets'].split("\n").map do |l|
    l = l.split(/\s+/)
    [l[0..3], l[4..-1].inject(0) do |a, b|
      (a << 8) + b.to_i
    end]
  end.to_h
  h['sites'].each_pair do |site_uid, hs|
    next if hs['scheduler'] == 'slurm'
    # forget about allocated ips for local vlans, since we are starting a new site
    allocated.delete_if { |_k, v| v[3] == 'local' }
    hs.fetch('clusters', {}).each_pair do |cluster_uid, hc|
      # skip clusters where kavlan is globally set to false (used for initial cluster installation)
      next unless hc['kavlan']

      hc['nodes'].each_pair do |node_uid, hn|
        raise "Node hash for #{node_uid} is nil" if hn.nil?
        raise "Old kavlan data in input/ for #{node_uid}" if hn.has_key?('kavlan')

        node_id = node_uid.split('-')[1].to_i
        hn['kavlan'] = {}
        hn['network_adapters'].to_a.select do |i|
          i[1]['mountable'] and (i[1]['kavlan'] or !i[1].has_key?('kavlan')) and i[1]['interface'] =~ %r{(FPGA/)?Ethernet}
        end.map { |e| e[0] }.each do |iface|
          hn['kavlan'][iface] = {}
          vlan_base.each do |vlan, v|
            type = v['type']
            base = IPAddress::IPv4.new(v['address']).to_u32
            k = [type, site_uid, cluster_uid, iface]
            raise "Missing VLAN offset for #{k}" unless vlan_offset.has_key?(k)

            ip = IPAddress::IPv4.parse_u32(base + vlan_offset[k] + node_id).to_s
            a = [site_uid, node_uid, iface, type, vlan]
            if allocated[ip]
              raise "IP already allocated: #{ip} (trying to add it to #{a} ; allocated to #{allocated[ip]})"
            end

            allocated[ip] = a
            hn['kavlan'][iface]["kavlan-#{vlan}"] = ip
          end
        end
      end
    end
  end
end

def add_tmp_kavlanng_adapters(h)
  h['sites'].each_pair do |_site_uid, hs|
    hs.fetch('clusters', {}).each_pair do |_cluster_uid, hc|
      hc['nodes'].each_pair do |_node_uid, hn|
        hn['kavlanng'] = {}
        hn['network_adapters'].to_a.select do |i|
          i[1]['mountable'] and (i[1]['kavlanng'] or !i[1].has_key?('kavlanng')) and i[1]['interface'] =~ %r{(FPGA/)?Ethernet}
        end.map { |e| e[0] }.each do |iface|
          hn['kavlanng'][iface] = true
        end
      end
    end
  end
end

def clean_tmp_kavlanng_adapters(h)
  h['sites'].each_pair do |_site_uid, hs|
    hs.fetch('clusters', {}).each_pair do |_cluster_uid, hc|
      hc['nodes'].each_pair do |_node_uid, hn|
        hn.delete('kavlanng')
      end
    end
  end
end

BMC_OFFSET = 256**2
IB_OFFSET = (256**2) * 2

def add_ipv4(h)
  allocated = {}
  base = IPAddress::IPv4.new(h['ipv4']['base']).to_u32
  sites_offsets = h['ipv4']['sites_offsets'].split("\n").map do |l|
    l = l.split(/\s+/)
    [l[0], l[1..-1].inject(0) do |a, b|
      (a << 8) + b.to_i
    end]
  end.to_h
  iface_offsets = h['ipv4']['iface_offsets'].split("\n").map do |l|
    l = l.split(/\s+/)
    [l[0..2], l[3..-1].inject(0) do |a, b|
      (a << 8) + b.to_i
    end]
  end.to_h
  h['sites'].each_pair do |site_uid, hs|
    hs.fetch('clusters', {}).each_pair do |cluster_uid, hc|
      hc['nodes'].each_pair do |node_uid, hn|
        # We don't generate JSON for retired nodes
        next if hn['status'] == 'retired'
        raise "Node hash for #{node_uid} is nil" if hn.nil?

        node_id = node_uid.split('-')[1].to_i
        hn['network_adapters'].each_pair do |iface, v|
          # We only consider interfaces that are either mountable, or management (BMC)
          next unless v['mountable'] or v['management']

          if iface == 'bmc'
            # We get the iface offset for BMC by adding the BMC_OFFSET to the iface_offset of the first prod interface
            prod_name = hn['network_adapters'].to_a.select do |e|
              e[1]['mounted'] and e[1]['interface'] == 'Ethernet'
            end.first[0]
            k = [site_uid, cluster_uid, prod_name]
            if_kind_offset = BMC_OFFSET
          elsif %w[InfiniBand Omni-Path].include?(v['interface'])
            # HPC interface can be defined inside the node-X.yaml file or generated from ipv4.yaml
            # if there's no 'netmask' entry, we assume that we don't want IPoIB, so no IP (g5k-postinstall won't configure it anyway)
            next unless v['netmask']

            k = [site_uid, cluster_uid, iface]
            unless iface_offsets.has_key?(k)
              puts "Warning: #{iface} offset should be defined for cluster #{cluster_uid} in ipv4.yaml"
              next
            end
            if_kind_offset = IB_OFFSET
          else
            # Ethernet interfaces must have an IP defined in ipv4.yaml
            k = [site_uid, cluster_uid, iface]
            if_kind_offset = 0
          end
          raise "Missing IPv4 information for #{k} (is IP defined in ipv4.yaml?)" unless iface_offsets.has_key?(k)

          ip = IPAddress::IPv4.parse_u32(base + sites_offsets[site_uid] + iface_offsets[k] + node_id + if_kind_offset).to_s
          a = [site_uid, node_uid, iface]
          if allocated[ip]
            raise "IP already allocated: #{ip} (trying to add it to #{a} ; allocated to #{allocated[ip]})"
          end

          allocated[ip] = a
          v['ip'] = ip
        end
      end
    end
  end
end

def add_ipv6(h)
  # for each node
  h['sites'].each_pair do |_site_uid, hs|
    site_prefix = IPAddress hs['ipv6']['prefix']
    hs.fetch('clusters', {}).each_pair do |_cluster_uid, hc|
      hc['nodes'].each_pair do |node_uid, hn|
        ipv6_adapters = hn['network_adapters'].select do |_k, v|
          v['mountable'] and ['Ethernet', 'FPGA/Ethernet'].include?(v['interface'])
        end
        next unless ipv6_adapters.length > 0
        unless ipv6_adapters.values[0]['mounted']
          raise "#{node_uid}: inconsistency: this code assumes first mountable ethernet adapter should be mounted: #{hn}"
        end

        ip4 = ipv6_adapters.values[0]['ip']
        ipv6_adapters.each_with_index do |(_iface, nah), idx|
          # compute and assign IPv6 based on IPv4 of the first adapter
          ip6 = IPAddress site_prefix.to_string
          ip6.prefix = 64
          ip6[4] = (ip4.split('.')[2].to_i & 0b1111) + 1
          ip6[5] = idx
          ip6[7] = ip4.split('.')[3].to_i
          nah['ip6'] = ip6.compressed
        end
      end
    end
  end
end

def add_kavlan_ipv6s(h)
  global_vlan_site = {}
  h['ipv6']['site_global_kavlans'].each { |key, value| global_vlan_site[value] = key }
  # Set kavlan ipv6 informations at site level
  h['sites'].each_pair do |site_uid, hs|
    next if hs['scheduler'] == 'slurm'
    site_prefix = IPAddress hs['ipv6']['prefix']
    kavlan_ids = h['vlans']['base'].map do |k, v|
      k if v['type'] =~ /local|routed/
    end.compact + [h['ipv6']['site_global_kavlans'][site_uid]]
    kavlan_ids.each do |kvl_id|
      kavlan_prefix = IPAddress site_prefix.to_string
      kavlan_prefix.prefix = 64
      case kvl_id
      when 1..3 # local non-routed
        kavlan_prefix[3] |= (kvl_id + 0x80 - 1)
        has_gateway = false
      when 4..9 # local routed
        kavlan_prefix[3] |= (kvl_id + 0x90 - 4)
        has_gateway = true
      else      # global
        kavlan_prefix[3] |= 0xA0
        has_gateway = true
      end
      hs['kavlans'][kvl_id]['network_ipv6'] = kavlan_prefix.to_string
      next unless has_gateway

      gateway = IPAddress kavlan_prefix.to_string
      if kvl_id > 9 # global kavlan gateway encodes site at an additional place
        gateway[4] = h['ipv6']['site_indexes'][site_uid] << 8
      end
      gateway[6] = 0xFFFF
      gateway[7] = 0xFFFF
      hs['kavlans'][kvl_id]['gateway_ipv6'] = gateway.compressed
    end
    prod_prefix = IPAddress site_prefix.to_string
    prod_prefix.prefix = 64
    gateway = IPAddress prod_prefix.to_string
    gateway[6] = 0xFFFF
    gateway[7] = 0xFFFF
    hs['kavlans']['default']['network_ipv6'] = prod_prefix.to_string
    hs['kavlans']['default']['gateway_ipv6'] = gateway.compressed
  end
  # Set kavlan ipv6 informations at node level
  h['sites'].each_pair do |site_uid, hs|
    hs.fetch('clusters', {}).each_pair do |_cluster_uid, hc|
      # skip clusters where kavlan is globally set to false (used for initial cluster installation)
      next unless hc['kavlan']

      hc['nodes'].each_pair do |node_uid, hn|
        kvl_adapters = hn['network_adapters'].select do |_k, v|
          v['mountable'] and (v['kavlan'] or !v.has_key?('kavlan')) and ['Ethernet',
                                                                         'FPGA/Ethernet'].include?(v['interface'])
        end
        next unless kvl_adapters.length > 0
        if kvl_adapters.length != hn['kavlan'].length
          raise "#{node_uid}: inconsistency: num kvl_adapters = #{kvl_adapters.length}, num kavlan entries = #{hn['kavlan'].length}"
        end
        unless kvl_adapters.values[0]['mounted']
          raise "#{node_uid}: inconsistency: this code assumes first kvl_adapters should be mounted: #{hn}"
        end

        ip4 = kvl_adapters.values[0]['ip']
        hn['kavlan6'] = {}
        kvl_adapters.each_with_index do |(iface, _nah), idx|
          hn['kavlan6'][iface] = {}
          hn['kavlan'][iface].each_key do |kvl|
            kvl_id = kvl.split('-')[1].to_i
            if kvl_id <= 9
              ip6 = IPAddress hs['kavlans'][kvl_id]['network_ipv6']
            else
              # The prefix is based on the site of the global kavlan, not the site of the node
              ip6 = IPAddress h['sites'][global_vlan_site[kvl_id]]['kavlans'][kvl_id]['network_ipv6']
              # global kavlan: set most signicant octet of interface part to site index
              ip6[4] = h['ipv6']['site_indexes'][site_uid] << 8
            end
            ip6[4] |= (ip4.split('.')[2].to_i & 0b1111) + 1
            ip6[5] = idx
            ip6[7] = ip4.split('.')[3].to_i
            hn['kavlan6'][iface]["kavlan-#{kvl_id}"] = ip6.compressed
          end
        end
      end
    end
  end
end

def add_software(h)
  # for each node
  h['sites'].each_pair do |_site_uid, hs|
    hs.fetch('clusters', {}).each_pair do |_cluster_uid, hc|
      hc['nodes'].each_pair do |_node_uid, hn|
        hn['software'] = {} unless hn.key?('software')
        hn['software']['postinstall-version'] = h['software']['postinstall-version']
        hn['software']['forced-deployment-timestamp'] = h['software']['forced-deployment-timestamp']
      end
    end
  end
end

def add_network_metrics(h)
  # for each cluster
  h['sites'].each_pair do |_site_uid, site|
    site.fetch('clusters', {}).each_pair do |_cluster_uid, cluster|
      # remove any network metrics defined in cluster
      cluster['metrics'] = cluster.fetch('metrics', []).reject { |m| m['name'] =~ /network_iface.*/ }

      # for each iface_uid found for cluster's nodes
      cluster['nodes'].select do |_, v|
        v['status'] != 'retired'
      end.map { |_, node| node['network_adapters'] }.map { |e| e.keys }.flatten.uniq.each do |iface_uid|
        # find switches connected to cluster's nodes interface with this uid
        switches = cluster['nodes'].select do |_, v|
          v['status'] != 'retired'
        end.map do |_, node|
          node['network_adapters'].fetch(iface_uid, {}).fetch('switch',
                                                              nil)
        end.uniq - [nil]
        next if switches.length == 0

        # for all metrics from those switches
        switches.map do |switch|
          site.fetch('networks', {}).fetch(switch, {}).fetch('metrics', []).select do |m|
            m['name'] =~ /network_iface.*/
          end
        end.flatten.uniq { |m| m['name'] }.each do |metric|
          new_metric = metric.merge({ 'labels' => { 'interface' => iface_uid } })
          new_metric['source'] = { 'protocol' => 'network_equipment' }

          # check if some cluster's nodes do not have this interface found in some network ports
          unless cluster['nodes'].select do |_, v|
            v['status'] != 'retired'
          end.map do |_, node|
            node['network_adapters'].fetch(iface_uid, {}).fetch('switch',
                                                                nil)
          end.all? do |s|
            !s.nil? and site.fetch('networks', {}).fetch(s, {}).fetch('metrics', []).select do |m|
              m['name'] == metric['name']
            end
          end
            # otherwise add "only_for" key to indicate nodes found
            new_metric['only_for'] = cluster['nodes'].select do |_, v|
              v['status'] != 'retired'
            end.select do |_, node|
              site.fetch('networks', {}).fetch(node['network_adapters'].fetch(iface_uid, {}).fetch('switch', 'notfound'), {}).fetch('metrics', []).find do |m|
                m['name'] == metric['name']
              end
            end.keys.sort_by { |node| node.split('-')[1].to_i }
          end
          cluster['metrics'].push(new_metric)
        end
      end
    end
  end
end

def add_pdu_metrics(h)
  # for each cluster
  h['sites'].each_pair do |_site_uid, site|
    site.fetch('clusters', {}).each_pair do |_cluster_uid, cluster|
      # remove any PDU metrics defined in cluster
      cluster['metrics'] = cluster.fetch('metrics', []).reject do |m|
        m['name'] =~ /^(wattmetre_power_watt|pdu_outlet_)/
      end

      # Do not add metric to cluster if PDU/wattmetre port is connected to several nodes at a time (shared PSU case)
      nodes_pdu_ports = cluster['nodes'].select do |_, v|
        v['status'] != 'retired'
      end.each_value.map { |node| node['pdu'] }.flatten
      # nodes pdu_ports has duplicate, meaning the a port is shared by several nodes
      next if nodes_pdu_ports.uniq.length != nodes_pdu_ports.length

      # get the list of PDUs used by the cluster
      cluster_pdus = cluster['nodes'].each_value.map do |node|
        node.fetch('pdu',
                   [])
      end.flatten.select do |p|
        !p.has_key?('kind') or p.fetch('kind',
                                       '') != 'wattmetre-only'
      end.map { |p| p['uid'] }.uniq

      # check if PDU have per-outlet monitoring then add the metric to the cluster
      # Metric is available for node only if a single PDU powers it
      if !cluster_pdus.empty? \
            and cluster_pdus.any? do |p|
                  site['pdus'][p].fetch('metrics', []).any? do |m|
                    /^pdu_outlet/ =~ m['name']
                  end
                end && !cluster['nodes'].each_value.any? do |node|
                         node.fetch('pdu', []).select do |p|
                           !p.has_key?('kind') or p.fetch('kind', '') != 'wattmetre-only'
                         end.map { |p| p['uid'] }.uniq.length > 1
                       end

        pdu = site['pdus'][cluster_pdus.find do |p|
          site['pdus'][p].fetch('metrics', []).any? do |m|
            /^pdu_outlet/ =~ m['name']
          end
        end]
        pdu.fetch('metrics', []).select { |m| /^pdu_outlet_/ =~ m['name'] }.each do |metric|
          new_metric = metric.clone
          new_metric['description'] = metric['description'].sub('per outlet', 'of node')
          new_metric['source'] = { 'protocol' => 'pdu' }

          # check if all cluster's nodes if found in pdus' ports or if some pdu do not have power metric
          if !cluster['nodes'].select { |_, v| v['status'] != 'retired' }.keys.all? do |node|
            cluster_pdus.any? do |p|
              site['pdus'][p].fetch('ports', []).has_value?(node)
            end
          end or cluster_pdus.any? do |p|
                   site['pdus'][p].fetch(
                     'metrics', []
                   ).none? do |m|
                     m['name'] == 'pdu_outlet_power_watt'
                   end
                 end

            # otherwise add "only_for" key to indicate nodes found
            new_metric['only_for'] = cluster['nodes'].keys.select do |node|
              cluster_pdus.any? do |p|
                site['pdus'][p].fetch('ports', []).has_value?(node) and site['pdus'][p].fetch('metrics', []).any? do |m|
                  m['name'] == 'pdu_outlet_power_watt'
                end
              end
            end.sort_by do |node|
              node.split('-')[1].to_i
            end
          end
          cluster['metrics'].insert(0, new_metric)
        end
      end

      # check PDU all have wattmetre monitoring and add the metric to the cluster
      if !cluster_pdus.empty? \
      and cluster_pdus.all? do |p|
            site['pdus'][p].fetch('metrics', []).any? do |m|
              m['name'] == 'wattmetre_power_watt'
            end
          end

        metric = site['pdus'][cluster_pdus.first].fetch('metrics', []).find { |m| m['name'] == 'wattmetre_power_watt' }
        new_metric = metric.merge({ 'description' => 'Power consumption of node reported by wattmetre, in watt' })
        # check if all cluster's nodes if found in wattmetres' ports
        unless cluster['nodes'].select { |_, v| v['status'] != 'retired' }.keys.all? do |node|
          cluster_pdus.any? do |p|
            site['pdus'][p].fetch('ports', []).has_value?(node)
          end
        end
          # otherwise add "only_for" key to indicate nodes found
          new_metric['only_for'] = cluster['nodes'].keys.select do |node|
            cluster_pdus.any? do |p|
              site['pdus'][p].fetch('ports', []).has_value?(node)
            end
          end.sort_by { |node| node.split('-')[1].to_i }
        end
        cluster['metrics'].insert(0, new_metric)
      end

      # get the list of "wattmetre-only" used by the cluster
      cluster_wm = cluster['nodes'].each_value.map do |node|
        node.fetch('pdu', [])
      end.flatten.select { |p| p.fetch('kind', '') == 'wattmetre-only' }.map { |p| p['uid'] }.uniq

      # check if they all have wattmetre monitoring and add the metric to the cluster
      next unless !cluster_wm.empty? \
      and cluster_wm.all? { |p| site['pdus'][p].fetch('metrics', []).any? { |m| m['name'] == 'wattmetre_power_watt' } }

      metric = site['pdus'][cluster_wm.first].fetch('metrics', []).find { |m| m['name'] == 'wattmetre_power_watt' }
      new_metric = metric.merge({ 'description' => 'Power consumption of node reported by wattmetre, in watt' })
      # check if all cluster's nodes if found in wattmetres' ports
      unless cluster['nodes'].select { |_, v| v['status'] != 'retired' }.keys.all? do |node|
        cluster_wm.any? do |p|
          site['pdus'][p].fetch('ports', []).has_value?(node)
        end
      end
        # otherwise add "only_for" key to indicate nodes found
        new_metric['only_for'] = cluster['nodes'].keys.select do |node|
          cluster_wm.any? do |p|
            site['pdus'][p].fetch('ports', []).has_value?(node)
          end
        end.sort_by { |node| node.split('-')[1].to_i }
      end
      cluster['metrics'].insert(0, new_metric)
    end
  end
end

def get_flops_per_cycle(microarch, cpu_name, cluster_uid)
  # Double precision operations each cycle, sources:
  # https://en.wikipedia.org/wiki/FLOPS
  # https://en.wikichip.org/wiki/WikiChip
  # https://ark.intel.com/
  case microarch
  when 'K8'
    return 2
  when 'Clovertown', 'Nehalem', 'Westmere', 'K10'
    return 4
  when 'Sandy Bridge', 'Ivy Bridge', 'Zen', 'Vulcan'
    return 8
  when 'Haswell', 'Broadwell', 'Zen 2', 'Zen 3', 'Sierra Forest', 'Ares'
    return 16
  when 'Ice Lake-SP'
    return 32
  when 'Zen 4', 'Zen 4c', 'Zen 5'
    # FIXME: Zen 5 value is uncertain
    return 48
  when 'Cascade Lake-SP', 'Skylake-SP'
    case cpu_name
    when /Silver 4110/, /Silver 4112/, /Silver 4114/, /Silver 4214/, /Silver 4215/, /Silver 4216/, /Gold 5218/, /Gold 5220/, /Gold 5115/, /Gold 5118/, /Gold 5120/, /Gold 5220R/
      return 16
    when /Gold 6126/, /Gold 6130/, /Gold 6142/, /Gold 6148/, /Gold 6154/, /Gold 6240/, /Gold 6248/, /Gold 6254/, /Gold 6240L/, /Gold 6230R/, /Gold 6238R/
      return 32
    end
    raise "Error: unknown CPU flop per cycle for #{cpu_name} (cluster #{cluster_uid}), cannot compute flops"
  # 4 64-bit FPUs, x2 for Fused Multiply-Add
  when /POWER8/
    return 8
  # FIXME: Find Jetson's FlopPerCycle
  when /Carmel/
    return 8
  # FIXME: Find Grace Hopper FlopPerCycle
  when /Grace/
    return 8
  # FIXME: Find Granite Rapids FlopPerCycle
  when 'Granite Rapids'
    return 8
  when 'Emerald Rapids'
    return 32
  when 'Sapphire Rapids'
    return 32
  end
  raise "Error: Unknown CPU architecture for cluster #{cluster_uid}, cannot compute flops"
end

def add_theorical_flops(h)
  h['sites'].each_pair do |_site_uid, site|
    site.fetch('clusters', {}).each_pair do |cluster_uid, cluster|
      cluster['nodes'].select { |_k, v| v['status'] != 'retired' }.each_pair do |_node_uid, node|
        node['performance'] = {}
        node['performance']['core_flops'] =
          node['processor']['clock_speed'].to_i * get_flops_per_cycle(node['processor']['microarchitecture'],
                                                                      node['processor']['other_description'], cluster_uid)
        node['performance']['node_flops'] =
          node['architecture']['nb_cores'].to_i * node['performance']['core_flops'].to_i
      end
    end
  end
end

def add_management_tools(h)
  h['sites'].each_pair do |_site_uid, site|
    site.fetch('clusters', {}).each_pair do |_cluster_uid, cluster|
      cluster['nodes'].select { |_k, v| v['status'] != 'retired' }.each_pair do |_node_uid, node|
        node['management_tools'] = h['management_tools'] unless node.has_key?('management_tools')
        h['management_tools'].each_key do |k|
          node['management_tools'][k] = h['management_tools'][k] unless node['management_tools'].has_key?(k)
        end
      end
    end
  end
end

def add_site_ipv6_infos(h)
  global_prefix = IPAddress h['ipv6']['prefix']
  h['sites'].each_pair do |site_uid, _hs|
    site_prefix = IPAddress global_prefix.to_string
    # Site index is third group of nibbles, but on the MSB side
    site_prefix[3] = h['ipv6']['site_indexes'][site_uid] << 8
    site_prefix.prefix = 56
    h['sites'][site_uid]['ipv6'] = {}
    h['sites'][site_uid]['ipv6']['prefix'] = site_prefix.to_string
    h['sites'][site_uid]['ipv6']['site_index'] = h['ipv6']['site_indexes'][site_uid]
    h['sites'][site_uid]['ipv6']['site_global_kavlan'] = h['ipv6']['site_global_kavlans'][site_uid]
  end
end

# This adds some extra pieces of information to the generated JSON:
#   - the compute capability for Nvidia GPUs
#   - the number of cores for all GPUs
#   - the microarch
#   - the theoretical flops performance
def add_gpu_information(h)
  h['sites'].each_pair do |_site_uid, site|
    site.fetch('clusters', {}).each_pair do |_cluster_uid, cluster|
      cluster['nodes'].select { |_k, v| v['status'] != 'retired' }.each_pair do |_node_uid, node|
        node['gpu_devices']&.each do |_, v|
          v['cores'] = GPURef.get_cores(v['model'])
          v['microarchitecture'] = GPURef.get_microarchitecture(v['model'])
          v['performance'] = GPURef.get_performance(v['model'])
          v['compute_capability'] = GPURef.get_compute_capability(v['model']) if v['vendor'] == 'Nvidia'
        end
      end
    end
  end
end

def get_port_pattern_subst(pattern, linecard_index, port_index)
  pattern.gsub('%LINECARD%', linecard_index.to_s).sub('%PORT%', port_index.to_s)
end

def get_port_pattern_interpolation(pattern, linecard_index, port_index)
  # reimplement with eval the ruby string interpolation mechanism (#{})
  # WARNING: it means that code from the input yaml will be executed (thus input yamls may be used as attack vectors)
  # return eval('"' + get_port_pattern_subst(pattern, linecard_index, port_index).gsub(/"/, '\"') + '"')
  eval('"' + get_port_pattern_subst(pattern, linecard_index, port_index) + '"')
end

def get_channel_pattern_subst(pattern, channel_name)
  pattern.gsub('%CHANNEL%', channel_name)
end

def get_channel_pattern_interpolation(pattern, channel_name)
  # reimplement with eval the ruby string interpolation mechanism (#{})
  # WARNING: it means that code from the input yaml will be executed (thus input yamls may be used as attack vectors)
  # return eval('"' + get_channel_pattern_subst(pattern, channel_name).gsub(/"/, '\"') + '"')
  eval('"' + get_channel_pattern_subst(pattern, channel_name) + '"')
end

def complete_one_network_equipment(network_uid, network)
  network['type'] = 'network_equipment'
  network['uid']  = network_uid

  # Change the format of linecard from Hash to Array
  linecards_array = []
  network['linecards'].each do |linecard_index, linecard|
    ports = []
    linecard.delete('ports').each do |port_index, port|
      unless port.nil?
        port = { 'uid' => port } if port.is_a? String
        # complete entries (see bug 8587)
        port['port'] = linecard['port'] if port['port'].nil? and linecard['port']
        port['kind'] = linecard['kind'] if port['kind'].nil? and linecard['kind']
        if port['switchport_mode'].nil? and linecard['switchport_mode'] and (port['kind'].nil? or port['kind'] != 'channel')
          # set switchport_mode of linecard if undefined, except if the port is part of a channel
          port['switchport_mode'] = linecard['switchport_mode']
        end
        port['snmp_pattern'] = linecard['snmp_pattern'] if port['snmp_pattern'].nil? and linecard['snmp_pattern']
        if port['snmp_pattern']
          port['snmp_name'] = get_port_pattern_subst(port['snmp_pattern'], linecard_index, port_index)
          port.delete('snmp_pattern')
        end
        port['ssh_pattern'] = linecard['ssh_pattern'] if port['ssh_pattern'].nil? and linecard['ssh_pattern']
        if port['ssh_pattern']
          port['ssh_name'] = get_port_pattern_interpolation(port['ssh_pattern'], linecard_index, port_index)
          port.delete('ssh_pattern')
        end
        if ((!linecard['kind'].nil? &&
             port['kind'].nil? &&
             linecard['kind'] == 'node') ||
             port['kind'] == 'node') &&
           port['port'].nil?
          p = port['uid'].match(/([a-z]*-[0-9]*)-?(.*)/).captures[1]
          port['port'] = p != '' ? p : 'eth0'
          port['uid'] = port['uid'].gsub(/-#{p}$/, '')
        end
      end
      ports[port_index] = port
    end
    linecard['ports'] = ports.map { |p| p || {} }
    linecards_array[linecard_index] = linecard
  end
  network['linecards'] = linecards_array.map { |l| l || {} }

  # Channels
  return unless network.key?('channels')

  network['channels'].each do |channel_name, channel|
    if channel['ssh_pattern'].nil? and network['channels_ssh_pattern']
      channel['ssh_pattern'] = network['channels_ssh_pattern']
    end
    if channel['ssh_pattern']
      channel['ssh_name'] = get_channel_pattern_interpolation(channel['ssh_pattern'], channel_name)
      channel.delete('ssh_pattern')
    end
  end
end

def complete_network_equipments(h)
  h['network_equipments'].each do |network_uid, network|
    complete_one_network_equipment(network_uid, network)
  end

  h['sites'].each do |_site_uid, site|
    site.fetch('networks', []).each do |network_uid, network|
      complete_one_network_equipment(network_uid, network)
    end
  end
end

def add_generic_metrics(h)
  generic_metrics = YAML.load_file(File.dirname(__FILE__) + '/generic_metrics.yaml')

  h['sites'].each_pair do |_site_uid, site|
    site.fetch('clusters', {}).each_pair do |cluster_uid, cluster|
      cluster['metrics'] = [] unless cluster['metrics']
      generic_metrics['prometheus'].each do |m|
        cluster['metrics'].append(m) unless cluster['metrics'].map { |cm| cm['name'] }.include?(m['name'])
      end
      gpu = cluster['nodes'].values.first.fetch('gpu_devices', { "nil": nil }).values.first
      next unless gpu \
      and gpu.fetch('device').start_with?('/dev/nvidia') \
      and GPURef.is_gpu_supported?(gpu) \
      and cluster_uid != 'hydra' # FIXME: to remove when hydra GPU is supported in std

      generic_metrics['prometheus-nvidia'].each do |m|
        cluster['metrics'].append(m) unless cluster['metrics'].map { |cm| cm['name'] }.include?(m['name'])
      end
    end

    site.fetch('pdus', {}).each_pair do |_pdu_uid, pdu|
      if pdu['vendor'] == 'Eaton' and pdu['model'] == 'EMAB20'
        pdu['metrics'] = pdu.fetch('metrics', []) + generic_metrics['eaton-emab-3p']
      elsif pdu['vendor'] == 'Eaton' and pdu['model'] == 'EMAB04'
        pdu['metrics'] = pdu.fetch('metrics', []) + generic_metrics['eaton-emab-3p']
        # Remove 2nd and 3rd phases metrics
        pdu['metrics'] = pdu['metrics'].select do |m|
          !m.has_key?('labels') or !m['labels'].has_key?('phase') or m['labels']['phase'] == 1
        end
      end
      pdu['metrics'].uniq! if pdu['metrics']
    end
  end
end
