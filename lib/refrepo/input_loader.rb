# Load a hierarchy of YAML file into a Ruby hash

require 'ipaddress'
require 'refrepo/hash/hash'
require 'refrepo/gen/reference-api'
require 'refrepo/gpu_ref'

def load_yaml_file_hierarchy(directory = File.expand_path("../../input/grid5000/", File.dirname(__FILE__)))

  global_hash = {} # the global data structure

  Dir.chdir(directory) {

    # Recursively list the .yaml files.
    # The order in which the results are returned depends on the system (http://ruby-doc.org/core-2.2.3/Dir.html).
    # => List deepest files first as they have lowest priority when hash keys are duplicated.
    list_of_yaml_files = Dir['**/*.y*ml', '**/*.y*ml.erb'].sort_by { |x| -x.count('/') }

    list_of_yaml_files.each { |filename|
      begin
        # Load YAML
        if /\.y.*ml\.erb$/.match(filename)
          # For files with .erb.yaml extensions, process the template before loading the YAML.
          file_hash = YAML::load(ERB.new(File.read(filename)).result(binding))
        else
          file_hash = YAML::load_file(filename)
        end
      if not file_hash
        raise StandardError.new("loaded hash is empty")
      end
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

    }

  }

#  pp global_hash

  detect_dead_nodes_with_yaml_files(global_hash)

  # add switch and port to nodes
  add_switch_port(global_hash)

  # add some ipv6 informations in sites
  add_site_ipv6_infos(global_hash)

  # populate each node with its IPv6
  add_ipv6(global_hash)

  # populate each node with its IPv4 addresses
  add_ipv4(global_hash)

  # populate each node with its kavlan IPs
  add_kavlan_ips(global_hash)
  add_kavlan_ipv6s(global_hash)

  # populate each node with software informations
  add_software(global_hash)

  # populate each cluster with metrics network information
  add_network_metrics(global_hash)

  # populate each node with theorical flops
  add_theorical_flops(global_hash)

  # add compute capability for nvidia gpus
  add_compute_capability(global_hash)

  # populate each node with administration tools' parameters
  add_management_tools(global_hash)

  add_default_values_and_mappings(global_hash)

  add_node_pdu_mapping(global_hash)

  add_wattmetre_mapping(global_hash)

  # populate each cluster with metrics PDU information
  add_pdu_metrics(global_hash)

  complete_network_equipments(global_hash)

  return global_hash
end

def add_node_pdu_mapping(h)
  h["sites"].each do |site_uid, site|
    site.fetch("pdus", []).each do |pdu_uid, pdu|

      # Get pdu information from node description in clusters/ hierachy
      pdu_attached_nodes = {}
      site.fetch("clusters", []).sort.each do |_cluster_uid, cluster|
        cluster["nodes"].each do |node_uid, node|# _sort_by_node_uid
          next if node['status'] == "retired"
          node.fetch('pdu', []).each do |node_pdu|
            if node_pdu["uid"] == pdu_uid
              pdu_attached_nodes[node_pdu["port"]] = node_uid
            end
          end
        end
      end

      # Merge pdu information from pdus/ hierachy into node information
      pdu.fetch("ports", {}).each do |port_uid, node_uid|
        node_uid = node_uid["uid"] if node_uid.is_a?(Hash)
        node = site["clusters"].fetch(node_uid.split("-")[0], {}).fetch("nodes", {}).fetch(node_uid, nil)
        next if not node
        node["pdu"] ||= []
        if node["pdu"].any?{|p| p["uid"] == pdu_uid && p["port"] == port_uid}
          raise "ERROR: Node #{node_uid}.#{site_uid} has PDU #{pdu_uid} description defined both in clusters/ and pdus/ hierarchy"
        end
        node["pdu"].append({"uid" => pdu_uid, "port" => port_uid})
      end

      # Merge pdu information from node description in pdus/ hierachy
      pdu_attached_nodes.each do |port_uid, node_uid|
        if pdu.fetch('ports', {}).key?(port_uid)
          raise "ERROR: Port #{port_uid} of #{pdu_uid}.#{site_uid} is defined both in PDU description and in node #{node_uid} description"
        end
        pdu["ports"] ||= {}
        pdu["ports"][port_uid] = node_uid
      end
    end
  end
end

def add_wattmetre_mapping(h)
  h["sites"].each do |site_uid, site|
    site.fetch("pdus", []).each do |pdu_uid, pdu|
      # Process wattmetre v3 information from pdus/ hierachy
      if pdu_uid.include?("wattmetrev3") # TODO: better way of identifying a V3 wattmetre
        wattmetre_modules = {}
        # Look for other PDUs where this wattmetre is used
        site.fetch("pdus", []).each do |_other_pdu_uid, other_pdu|
          other_pdu.fetch("ports", {}).each do |other_port_uid, other_port_data|
            next if not other_port_data.is_a?(Hash)
            next if other_port_data["wattmetre"] != pdu_uid
            mod = other_port_data["module"].to_i
            chan = other_port_data["channel"].to_i
            node_uid = other_port_data["uid"]
            if not wattmetre_modules[mod]
              wattmetre_modules[mod] = {}
            end
            wattmetre_modules[mod][chan] = node_uid
            # Convert PDU port's full Hash to string w/ node uid for generated data
            other_pdu["ports"][other_port_uid] = node_uid
          end
        end
        # Wattmetre ports are numbered by modules serial, then by channels inside module
        wattmetre_modules.sort.each_with_index do |m, module_idx|
          channels = m[1]
          channels.sort.sort.each_with_index do |c, chan_idx|
            node_uid = c[1]
            # Each module has 6 channels
            port_num = module_idx*6 + chan_idx

            pdu["ports"] ||= {}
            if pdu['ports'].key?(port_num)
              raise "ERROR: Port #{port_num} of #{pdu_uid}.#{site_uid} is defined both in wattmetre description and in other PDUs' port info"
            end

            # Add mapping to wattmetre description under pdus/ hierarchy
            pdu["ports"][port_num] = node_uid

            # Add mapping to node description under clusters/ hierarchy
            node = site["clusters"].fetch(node_uid.split("-")[0], {}).fetch("nodes", {}).fetch(node_uid, nil)
            node["pdu"] ||= []
            if node["pdu"].any?{|p| p["uid"] == pdu_uid && p["port"] == port_num}
              raise "ERROR: Node #{node_uid}.#{site_uid} has PDU #{pdu_num} description defined both in clusters/ and pdus/ hierarchy"
            end
            node["pdu"].append({"uid" => pdu_uid, "port" => port_num, "kind" => "wattmetre-only"})
          end
        end
      end
    end
  end
end

def add_default_values_and_mappings(h)
  h["sites"].each do |site_uid, site|

    site.fetch("pdus", []).each do |pdu_uid, pdu|
      pdu["type"] = "pdu"
      pdu["uid"]  = pdu_uid
    end

    site.fetch("servers", []).each do |server_uid, server|
      server["type"]  = "server"
      server["uid"]  = server_uid
    end

    site.fetch("clusters", []).sort.each do |cluster_uid, cluster|

      #
      # Write cluster info
      #

      cluster["type"] = "cluster"
      cluster["uid"]  = cluster_uid
      cluster["exotic"] = cluster.key?('exotic') ? cluster['exotic'] : false

      # On the previous version of this script, cluster["created_ad"] was generated from a Ruby Time. cluster["created_ad"] is now a Ruby Date at JSON import.
      # As Date.httpdate and Time.httpdate does not behave the same with timezone, it is converted here as a Ruby time.
      cluster["created_at"] = Date.parse(cluster["created_at"].to_s).httpdate

      #
      # Write node info
      #

      cluster["nodes"].each do |node_uid, node|# _sort_by_node_uid
        #puts node_uid

        node["uid"] = node_uid
        node["type"] = "node"
        if node.key?("processor")
          node["processor"]["cache_l1"] ||= nil
        end

        # Add default keys
        node["main_memory"] = {} unless node.key?("main_memory")

        node["exotic"] = cluster.key?('exotic') ? cluster['exotic'] : false unless node.key?('exotic')

        node['supported_job_types']['queues'] = cluster['queues'] unless node['supported_job_types'].key?('queues')

        # Delete keys
        #raise 'node["storage_devices"] is nil' if node["storage_devices"].nil?
        Hash(node["storage_devices"]).keys.each { |key|
          node["storage_devices"][key].delete("timeread")  if node["storage_devices"][key].key?("timeread")
          node["storage_devices"][key].delete("timewrite") if node["storage_devices"][key].key?("timewrite")
        }

        # Ensure that id (diskN) is present
        node["storage_devices"].each do |key, hash|
          raise "Missing id for disk #{key} from cluster input" if !hash['id']
        end

        # Add vendor info to storage
        node["storage_devices"].each do |key, hash|
          next if node['status'] == "retired" # we do not bother for retired nodes

          matching_vendor = {}
          matching_interface = []
          h['disk_vendor_model_mapping'].each do |interface, vendor|
            vendor.select do |k, v|
              matching_vendor[k] = v if v.include? hash["model"]
              matching_interface << interface if v.include? hash["model"]
            end
          end

          raise "Model \"#{hash["model"]}\" don't match any vendor in input/grid5000/disks.yaml" if matching_vendor.empty?
          raise "Model \"#{hash["model"]}\" specify in multiple vendors: #{matching_vendor.keys} in input/grid5000/disks.yaml" if matching_vendor.length > 1
          raise "Model \"#{hash["model"]}\" specify in multiple interface: #{matching_interface} in input/grid5000/disks.yaml" if matching_interface.length > 1 unless hash["model"] == "unknown"
          hash['vendor'] = matching_vendor.keys.first

          if matching_interface.first != 'RAID' && hash['interface'] != matching_interface.first
            raise "Interface \"#{hash['interface']}\" for disk #{key} (model #{hash["model"]}) does not match interface \"#{matching_interface.first}\" in input/grid5000/disks.yaml"
          end
        end

        # Ensure that by_id is present (bug 11043)
        node["storage_devices"].each do |_key, hash|
          hash['by_id'] = '' if not hash['by_id']
        end

        # Type conversion
        node["network_adapters"].each { |_key, hash| hash["rate"] = hash["rate"].to_i if hash["rate"].is_a?(Float) }

        # For each network adapters, populate "network_address", "switch" and "switch_port" from the network equipment description
        node["network_adapters"].each_pair { |device, network_adapter|
          network_adapter["mac"] = network_adapter["mac"].downcase if network_adapter["mac"].is_a?(String)

          # infiniband properties
          network_adapter["ib_switch_card"]     = network_adapter.delete("line_card") if network_adapter.key?("line_card")
          network_adapter["ib_switch_card_pos"] = network_adapter.delete("position")  if network_adapter.key?("position")

          if network_adapter["management"]
            # Management network_adapter (bmc)
            network_adapter["network_address"] = "#{node_uid}-bmc.#{site_uid}.grid5000.fr" unless network_adapter.key?("network_address")
          elsif network_adapter["mounted"] and /^eth[0-9]$/.match(device)
            # Primary network_adapter
            network_adapter["network_address"] = "#{node_uid}.#{site_uid}.grid5000.fr" if network_adapter["enabled"]
          else
            # Secondary network_adapter(s)
            network_adapter["network_address"] = "#{node_uid}-#{device}.#{site_uid}.grid5000.fr" if network_adapter["mountable"] && !network_adapter.key?("network_address")
          end
          # If kavlan entry is not defined here, set it node's kavlan description
          if not network_adapter["kavlan"]
            if node["kavlan"].nil?
              network_adapter["kavlan"] = false
            else
              network_adapter["kavlan"] = node["kavlan"].keys.include?(device) ? true : false
            end
          end

          network_adapter.delete("network_address") if network_adapter["network_address"] == 'none'
        }

        if node.key?("pdu")

          node["pdu"].each { |p|
            pdu = [p].flatten
            pdu.each { |item|
              #See https://intranet.grid5000.fr/bugzilla/show_bug.cgi?id=7585, workaround to validate node pdu that have per_outlets = false
              item.delete("port") if item["port"] == "disabled"
            }
          }
        end # node.key?("pdu")
      end
    end

  end
end

def sorted_vlan_offsets
  offsets = load_yaml_file_hierarchy['vlans']['offsets'].split("\n").
    map { |l| l = l.split(/\s+/) ; (4..7).each { |e| l[e] = l[e].to_i } ; l }
  # for local VLANs, we include the site when we sort
  puts offsets.select { |l| l[0] == 'local' }.
   sort_by { |l| [l[0], l[1] ] + l[4..-1] }.
   map { |l| l.join(' ') }.
   join("\n")
  puts offsets.select { |l| l[0] != 'local' }.
   sort_by { |l| [l[0] ] + l[4..-1] }.
   map { |l| l.join(' ') }.
   join("\n")
end

# Parse network equipment description and return switch name and port connected to given node
#  In the network description, if the node interface is given (using "port" attribute),
#  the interface parameter must be used.
def net_switch_port_lookup(site, node_uid, interface='')
  site["networks"].each do |switch_uid, switch|
    switch["linecards"].each do |lc_uid,lc|
      lc["ports"].each do |port_uid,port|
        if port.is_a?(Hash)
          switch_remote_port = port["port"] || lc["port"] || ""
          switch_remote_uid = port["uid"]
        else
          switch_remote_port = lc["port"] || ""
          switch_remote_uid = port
        end
        if switch_remote_uid =~ /([a-z]*-[0-9]*)-(.*)/
          n, p = switch_remote_uid.match(/([a-z]*-[0-9]*)-(.*)/).captures
          switch_remote_uid = n
          switch_remote_port = p
        end
        if switch_remote_uid == node_uid and switch_remote_port == interface
          # Build port name from snmp_naming_pattern
          # Example: '3 2 GigabitEthernet%LINECARD%/%PORT%' -> 'GigabitEthernet3/2'
          pattern = port["snmp_pattern"] || lc["snmp_pattern"] || ""
          port_name = pattern.sub("%LINECARD%",lc_uid.to_s).sub("%PORT%",port_uid.to_s)
          return switch_uid, port_name
        end
      end
    end
  end
  return nil
end

def add_switch_port(h)
  h['sites'].each_pair do |_site_uid, site|
    used_ports = {}
    site['clusters'].each_pair do |_cluster_uid, hc|
      hc['nodes'].each_pair do |node_uid, hn|
        next if hn['status'] == 'retired'
        hn['network_adapters'].each_pair do |iface_uid, iface|
          if (iface['mounted'] or iface['mountable']) and not iface['management'] and iface['interface'] =~ /(fpga|Ethernet)/
            switch, swport = net_switch_port_lookup(site, node_uid, iface_uid) || net_switch_port_lookup(site, node_uid)
            if used_ports[[switch, swport]]
              raise "Duplicate port assigned for #{node_uid} #{iface_uid}. Already assigned to #{used_ports[[switch, swport]]} Aborting."
            end
            used_ports[[switch, swport]] = [node_uid, iface_uid]
            iface['switch'], iface['switch_port'] = switch, swport
          end
        end
      end
    end
  end
end

def detect_dead_nodes_with_yaml_files(h)
  h['sites'].each_pair do |_site_uid, hs|
    hs['clusters'].each_pair do |_cluster_uid, hc|
      hc['nodes'].each_pair do |node_uid, hn|
        if hn['status'] == 'retired'
          if (hn['processor']['model'] rescue nil)
            raise "ERROR: #{node_uid} is marked status:retired, but its yaml is still in the repository. Please remove it."
          end
        end
      end
    end
  end
end

def add_kavlan_ips(h)
  allocated = {}
  vlan_base = h['vlans']['base']
  vlan_offset = h['vlans']['offsets'].split("\n").map { |l| l = l.split(/\s+/) ; [ l[0..3], l[4..-1].inject(0) { |a, b| (a << 8) + b.to_i } ] }.to_h
  h['sites'].each_pair do |site_uid, hs|
    # forget about allocated ips for local vlans, since we are starting a new site
    allocated.delete_if { |_k, v| v[3] == 'local' }
    hs['clusters'].each_pair do |cluster_uid, hc|
      next if !hc['kavlan'] # skip clusters where kavlan is globally set to false (used for initial cluster installation)
      hc['nodes'].each_pair do |node_uid, hn|
        raise "Node hash for #{node_uid} is nil" if hn.nil?
        raise "Old kavlan data in input/ for #{node_uid}" if hn.has_key?('kavlan')
        node_id = node_uid.split('-')[1].to_i
        hn['kavlan'] = {}
        hn['network_adapters'].to_a.select { |i| i[1]['mountable'] and (i[1]['kavlan'] or not i[1].has_key?('kavlan')) and i[1]['interface'] =~ /(FPGA\/)?Ethernet/ }.map { |e| e[0] }.each do |iface|
          hn['kavlan'][iface] = {}
          vlan_base.each do |vlan, v|
            type = v['type']
            base = IPAddress::IPv4::new(v['address']).to_u32
            k = [type, site_uid, cluster_uid, iface]
            if not vlan_offset.has_key?(k)
              raise "Missing VLAN offset for #{k}"
            end
            ip = IPAddress::IPv4::parse_u32(base + vlan_offset[k] + node_id).to_s
            a = [ site_uid, node_uid, iface, type, vlan ]
            raise "IP already allocated: #{ip} (trying to add it to #{a} ; allocated to #{allocated[ip]})" if allocated[ip]
            allocated[ip] = a
            hn['kavlan'][iface]["kavlan-#{vlan}"] = ip
          end
        end
      end
    end
  end
end

def add_ipv4(h)
  allocated = {}
  base = IPAddress::IPv4::new(h['ipv4']['base']).to_u32
  sites_offsets = h['ipv4']['sites_offsets'].split("\n").map { |l| l = l.split(/\s+/) ; [ l[0], l[1..-1].inject(0) { |a, b| (a << 8) + b.to_i } ] }.to_h
  iface_offsets = h['ipv4']['iface_offsets'].split("\n").map { |l| l = l.split(/\s+/) ; [ l[0..2], l[3..-1].inject(0) { |a, b| (a << 8) + b.to_i } ] }.to_h
  h['sites'].each_pair do |site_uid, hs|
    hs['clusters'].each_pair do |cluster_uid, hc|
      hc['nodes'].each_pair do |node_uid, hn|
        raise "Node hash for #{node_uid} is nil" if hn.nil?
        node_id = node_uid.split('-')[1].to_i
        hn['network_adapters'].each_pair do |iface, v|
          # only allocate mountable ethernet interfaces
          next if not (v['mountable'] and ['Ethernet','FPGA/Ethernet'].include?(v['interface']))
          k = [site_uid, cluster_uid, iface]
          if not iface_offsets.has_key?(k)
            raise "Missing IPv4 information for #{k}"
          end
          ip = IPAddress::IPv4::parse_u32(base + sites_offsets[site_uid] + iface_offsets[k] + node_id).to_s
          a = [ site_uid, node_uid, iface ]
          raise "IP already allocated: #{ip} (trying to add it to #{a} ; allocated to #{allocated[ip]})" if allocated[ip]
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
    hs['clusters'].each_pair do |_cluster_uid, hc|
      hc['nodes'].each_pair do |node_uid, hn|
        ipv6_adapters = hn['network_adapters'].select { |_k,v| v['mountable'] and ['Ethernet','FPGA/Ethernet'].include?(v['interface']) }
        if ipv6_adapters.length > 0
          if not ipv6_adapters.values[0]['mounted']
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
end

def add_kavlan_ipv6s(h)
  global_vlan_site = {}
  h['ipv6']['site_global_kavlans'].each { |key, value| global_vlan_site[value] = key }
  # Set kavlan ipv6 informations at site level
  h['sites'].each_pair do |site_uid, hs|
    site_prefix = IPAddress hs['ipv6']['prefix']
    kavlan_ids = h['vlans']['base'].map{ |k,v| k if v["type"] =~ /local|routed/ }.compact + [h['ipv6']['site_global_kavlans'][site_uid]]
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
      if has_gateway
        gateway = IPAddress kavlan_prefix.to_string
        if kvl_id > 9 # global kavlan gateway encodes site at an additional place
          gateway[4] = h['ipv6']['site_indexes'][site_uid] << 8
        end
        gateway[6] = 0xFFFF
        gateway[7] = 0xFFFF
        hs['kavlans'][kvl_id]['gateway_ipv6'] = gateway.compressed
      end
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
    hs['clusters'].each_pair do |_cluster_uid, hc|
      next if !hc['kavlan'] # skip clusters where kavlan is globally set to false (used for initial cluster installation)
      hc['nodes'].each_pair do |node_uid, hn|
        kvl_adapters = hn['network_adapters'].select { |_k,v| v['mountable'] and (v['kavlan'] or not v.has_key?('kavlan')) and ['Ethernet','FPGA/Ethernet'].include?(v['interface']) }
        if kvl_adapters.length > 0
          if kvl_adapters.length != hn['kavlan'].length
            raise "#{node_uid}: inconsistency: num kvl_adapters = #{kvl_adapters.length}, num kavlan entries = #{hn['kavlan'].length}"
          end
          if not kvl_adapters.values[0]['mounted']
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
end

def add_software(h)
  # for each node
  h['sites'].each_pair do |_site_uid, hs|
    hs['clusters'].each_pair do |_cluster_uid, hc|
      hc['nodes'].each_pair do |_node_uid, hn|
        if not hn.key?('software')
          hn['software'] = {}
        end
        hn['software']['postinstall-version'] = h['software']['postinstall-version']
        hn['software']['forced-deployment-timestamp'] = h['software']['forced-deployment-timestamp']
      end
    end
  end
end

def add_network_metrics(h)
  # for each cluster
  h['sites'].each_pair do |_site_uid, site|
    site['clusters'].each_pair do |_cluster_uid, cluster|

      # remove any network metrics defined in cluster
      cluster['metrics'] = cluster.fetch('metrics', []).reject {|m| m['name'] =~ /network_iface.*/}

      # for each interface of a cluster's node
      _, node = cluster['nodes'].select { |_k, v| v['status'] != 'retired' }.sort_by{ |k, _v| k }.first
      node["network_adapters"].each do |iface_uid, iface|

        # we only support metrics for Ethernet at this point
        next if iface['interface'] != 'Ethernet'

        # get switch attached to interface
        switch = iface['switch']

        # for each network metric declared for the switch
        site.fetch('networks', {}).fetch(switch, {}).fetch('metrics', []).select{|m| m['name'] =~ /network_iface.*/}.each do |metric|

          # add this metric to cluster's list of available metrics, associated to node interface
          new_metric = metric.merge({"labels" => {"interface" => iface_uid}})
          new_metric["source"] = {"protocol" => "network_equipment"}
          cluster['metrics'].push(new_metric)
        end
      end
    end
  end
end

def add_pdu_metrics(h)
  # for each cluster
  h['sites'].each_pair do |_site_uid, site|
    site['clusters'].each_pair do |_cluster_uid, cluster|

      # remove any PDU metrics defined in cluster
      cluster['metrics'] = cluster.fetch('metrics', []).reject {|m| m['name'] =~ /(wattmetre_power_watt|pdu_outlet_power_watt)/ }

      # get the list of "wattmetre-only" used by the cluster
      cluster_wm = cluster['nodes'].each_value.map{|node| node.fetch('pdu', [])}.flatten.select{|p| p.fetch('kind', '') == 'wattmetre-only'}.map{|p| p['uid']}.uniq

      # check if they all have wattmetre monitoring and add the metric to the cluster
      if not cluster_wm.empty? \
      and cluster_wm.all?{|pdu| site['pdus'][pdu].fetch('metrics', []).any?{|m| m['name'] == 'wattmetre_power_watt'}}

        metric = site['pdus'][cluster_wm.first].fetch('metrics', []).select{|m| m['name'] == 'wattmetre_power_watt'}.first
        new_metric = metric.merge({'description' => "Power consumption of node reported by wattmetre, in watt"})
        cluster['metrics'].insert(0, new_metric)
      end

      # get the list of PDUs used by the cluster
      cluster_pdus = cluster['nodes'].each_value.map{|node| node.fetch('pdu', [])}.flatten.select{|p| not p.has_key?('kind') or p.fetch('kind', '') != 'wattmetre-only'}.map{|p| p['uid']}.uniq

      # check if they all have wattmetre monitoring and add the metric to the cluster
      if not cluster_pdus.empty? \
      and cluster_pdus.all?{|pdu| site['pdus'][pdu].fetch('metrics', []).any?{|m| m['name'] == 'wattmetre_power_watt'}}

        metric = site['pdus'][cluster_pdus.first].fetch('metrics', []).select{|m| m['name'] == 'wattmetre_power_watt'}.first
        new_metric = metric.merge({'description' => "Power consumption of node reported by wattmetre, in watt"})
        cluster['metrics'].insert(0, new_metric)
      end

      # check if PDU have monitoring then add the metric to the cluster
      if not cluster_pdus.empty? \
      and cluster_pdus.all?{|pdu| site['pdus'][pdu].fetch('metrics', []).any?{|m| m['name'] == 'pdu_outlet_power_watt'}}

        # Metric is available for node only if a single PDU powers it
        if not cluster['nodes'].each_value.any?{|node| node.fetch('pdu', []).select{|p| not p.has_key?('kind') or p.fetch('kind', '') != 'wattmetre-only'}.map{|p| p['uid']}.uniq.length > 1}
          metric = site['pdus'][cluster_pdus.first].fetch('metrics', []).select{|m| m['name'] == 'pdu_outlet_power_watt'}.first
          new_metric = metric.merge({'description' => "Power consumption of node reported by PDU, in watt"})
          new_metric['source'] = {"protocol" => "pdu"}
          cluster['metrics'].insert(0, new_metric)
        end
      end
    end
  end
end

def get_flops_per_cycle(microarch, cpu_name)
  # Double precision operations each cycle, sources:
  # https://en.wikipedia.org/wiki/FLOPS
  # https://en.wikichip.org/wiki/WikiChip
  # https://ark.intel.com/
  case microarch
  when "K8"
    return 2
  when "Clovertown", "Nehalem", "Westmere", "K10"
    return 4
  when "Sandy Bridge", "Zen", "Vulcan"
    return 8
  when "Haswell", "Broadwell", "Zen 2"
    return 16
  when "Cascade Lake-SP", "Skylake"
    case cpu_name
    when /Silver 4110/, /Gold 5218/, /Gold 5220/
      return 16
    when /Gold 6126/, /Gold 6130/
      return 32
    end
  # 4 64-bit FPUs, x2 for Fused Multiply-Add
  when /POWER8/
    return 8
  end
  raise "Error: Unknown CPU architecture, cannot compute flops"
end

def add_theorical_flops(h)
  h['sites'].each_pair do |_site_uid, site|
    site['clusters'].each_pair do |_cluster_uid, cluster|
      cluster['nodes'].select { |_k, v| v['status'] != 'retired' }.each_pair do |_node_uid, node|
        node['performance'] = {}
        node['performance']['core_flops'] =  node['processor']['clock_speed'].to_i * get_flops_per_cycle(node['processor']['microarchitecture'], node['processor']['other_description'])
        node['performance']['node_flops'] = node['architecture']['nb_cores'].to_i * node['performance']['core_flops'].to_i
      end
    end
  end
end

def add_management_tools(h)
  h['sites'].each_pair do |_site_uid, site|
    site['clusters'].each_pair do |_cluster_uid, cluster|
      cluster['nodes'].select { |_k, v| v['status'] != 'retired' }.each_pair do |_node_uid, node|
        node['management_tools'] = h['management_tools'] if !node.has_key?('management_tools')
        h['management_tools'].each_key do |k|
          node['management_tools'][k] = h['management_tools'][k] if !node['management_tools'].has_key?(k)
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

def add_compute_capability(h)
  h['sites'].each_pair do |_site_uid, site|
    site['clusters'].each_pair do |_cluster_uid, cluster|
      cluster['nodes'].select { |_k, v| v['status'] != 'retired' }.each_pair do |_node_uid, node|
        if node['gpu_devices']
          node['gpu_devices'].select { |_, v| v['vendor'] == 'Nvidia' }.each do |_, v|
            v['compute_capability'] = GPURef.get_compute_capability(v['model'])
          end
        end
      end
    end
  end
end

def complete_one_network_equipment(network_uid, network)
  network["type"] = "network_equipment"
  network["uid"]  = network_uid

  # Change the format of linecard from Hash to Array
  linecards_array = []
  network["linecards"].each do |linecard_index, linecard|
    ports = []
    linecard.delete("ports").each do |port_index, port|
      if not port.nil?
        port = { "uid"=> port } if port.is_a? String
        # complete entries (see bug 8587)
        if port['port'].nil? and linecard['port']
          port['port'] = linecard['port']
        end
        if port['kind'].nil? and linecard['kind']
          port['kind'] = linecard['kind']
        end
        if port['snmp_pattern'].nil? and linecard['snmp_pattern']
          port['snmp_pattern'] = linecard['snmp_pattern']
        end
        if port['snmp_pattern']
          port['snmp_name'] = port['snmp_pattern']
          .sub('%LINECARD%',linecard_index.to_s).sub('%PORT%',port_index.to_s)
          port.delete('snmp_pattern')
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
    linecard["ports"] = ports.map { |p| p || {} }
    linecards_array[linecard_index] = linecard
  end
  network["linecards"] = linecards_array.map{|l| l || {}}
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
