# Load a hierarchy of YAML file into a Ruby hash

require 'ipaddress'
require 'refrepo/hash/hash'
require 'refrepo/gen/reference-api'

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
        raise Exception.new("loaded hash is empty")
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

  # populate each cluster with metrics PDU information
  add_pdu_metrics(global_hash)

  # populate each node with theorical flops
  add_theorical_flops(global_hash)

  return global_hash
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


def add_kavlan_ips(h)
  allocated = {}
  vlan_base = h['vlans']['base']
  vlan_offset = h['vlans']['offsets'].split("\n").map { |l| l = l.split(/\s+/) ; [ l[0..3], l[4..-1].inject(0) { |a, b| (a << 8) + b.to_i } ] }.to_h
  h['sites'].each_pair do |site_uid, hs|
    # forget about allocated ips for local vlans, since we are starting a new site
    allocated.delete_if { |k, v| v[3] == 'local' }
    hs['clusters'].each_pair do |cluster_uid, hc|
      next if !hc['kavlan'] # skip clusters where kavlan is globally set to false (used for initial cluster installation)
      hc['nodes'].each_pair do |node_uid, hn|
        raise "Node hash for #{node_uid} is nil" if hn.nil?
        raise "Old kavlan data in input/ for #{node_uid}" if hn.has_key?('kavlan')
        node_id = node_uid.split('-')[1].to_i
        hn['kavlan'] = {}
        hn['network_adapters'].to_a.select { |i| i[1]['mountable'] and (i[1]['kavlan'] or not i[1].has_key?('kavlan')) and i[1]['interface'] == 'Ethernet' }.map { |e| e[0] }.each do |iface|
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
          next if not (v['mountable'] and v['interface'] == 'Ethernet')
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
  h['sites'].each_pair do |site_uid, hs|
    site_prefix = IPAddress hs['ipv6']['prefix']
    hs['clusters'].each_pair do |cluster_uid, hc|
      hc['nodes'].each_pair do |node_uid, hn|
        ipv6_adapters = hn['network_adapters'].select { |_k,v| v['mountable'] and v['interface'] == 'Ethernet' }
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
        kvl_adapters = hn['network_adapters'].select { |_k,v| v['mountable'] and (v['kavlan'] or not v.has_key?('kavlan')) and v['interface'] == 'Ethernet' }
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
  h['sites'].each_pair do |site_uid, hs|
    hs['clusters'].each_pair do |cluster_uid, hc|
      hc['nodes'].each_pair do |node_uid, hn|
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
  h['sites'].each_pair do |site_uid, site|
    site['clusters'].each_pair do |cluster_uid, cluster|

      # remove any network metrics defined in cluster
      cluster['metrics'] = cluster.fetch('metrics', []).reject {|m| m['name'] =~ /network_.*_bytes_total/}

      # for each interface of a cluster's node
      node_uid, node = cluster['nodes'].select { |k, v| v['status'] != 'retired' }.sort_by{ |k, v| k }.first
      node["network_adapters"].each do |iface_uid, iface|

        # get switch attached to interface
        if iface['mounted'] and not iface['management'] and iface['interface'] == 'Ethernet'
          switch, _ = net_switch_port_lookup(site, node_uid, iface_uid) || net_switch_port_lookup(site, node_uid)
        else
          switch, _ = net_switch_port_lookup(site, node_uid, iface_uid)
        end

        # for each network metric declared for the switch
        site.fetch('networks', {}).fetch(switch, {}).fetch('metrics', []).select{|m| m['name'] =~ /network_.*_bytes_total/}.each do |metric|

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
  h['sites'].each_pair do |site_uid, site|
    site['clusters'].each_pair do |cluster_uid, cluster|

      # remove any PDU metrics defined in cluster
      cluster['metrics'] = cluster.fetch('metrics', []).reject {|m| m['name'] =~ /(wattmetre_power_watt|pdu_outlet_power_watt)/ }

      # get the list of "wattmetre-only" used by the cluster
      cluster_wm = cluster['nodes'].each_value.map{|node| node.fetch('pdu', [])}.flatten.select{|p| p.fetch('kind', '') == 'wattmetre-only'}.map{|p| p['uid']}.uniq

      # check if they all have wattmetre monitoring and add the metric to the cluster
      if not cluster_wm.empty? \
      and cluster_wm.all?{|pdu| site['pdus'][pdu].fetch('metrics', []).any?{|m| m['name'] == 'wattmetre_power_watt'}}

        metric = site['pdus'][cluster_wm.first].fetch('metrics', []).each{|m| m['name'] == 'wattmetre_power_watt'}.first
        new_metric = metric.merge({'description' => "Power consumption of node reported by wattmetre, in watt"})
        cluster['metrics'].insert(0, new_metric)
      end

      # get the list of PDUs used by the cluster
      cluster_pdus = cluster['nodes'].each_value.map{|node| node.fetch('pdu', [])}.flatten.select{|p| not p.has_key?('kind') or p.fetch('kind', '') != 'wattmetre-only'}.map{|p| p['uid']}.uniq

      # check if they all have wattmetre monitoring and add the metric to the cluster
      if not cluster_pdus.empty? \
      and cluster_pdus.all?{|pdu| site['pdus'][pdu].fetch('metrics', []).any?{|m| m['name'] == 'wattmetre_power_watt'}}

        metric = site['pdus'][cluster_pdus.first].fetch('metrics', []).each{|m| m['name'] == 'wattmetre_power_watt'}.first
        new_metric = metric.merge({'description' => "Power consumption of node reported by wattmetre, in watt"})
        cluster['metrics'].insert(0, new_metric)
      end

      # check if PDU have monitoring then add the metric to the cluster
      if not cluster_pdus.empty? \
      and cluster_pdus.all?{|pdu| site['pdus'][pdu].fetch('metrics', []).any?{|m| m['name'] == 'pdu_outlet_power_watt'}}

        # Metric is available for node only if a single PDU powers it
        if not cluster['nodes'].each_value.any?{|node| node.fetch('pdu', []).select{|p| not p.has_key?('kind') or p.fetch('kind', '') != 'wattmetre-only'}.map{|p| p['uid']}.uniq.length > 1}
          metric = site['pdus'][cluster_pdus.first].fetch('metrics', []).each{|m| m['name'] == 'pdu_outlet_power_watt'}.first
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
  when "Haswell", "Broadwell"
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
  h['sites'].each_pair do |site_uid, site|
    site['clusters'].each_pair do |cluster_uid, cluster|
      cluster['nodes'].select { |k, v| v['status'] != 'retired' }.each_pair do |node_uid, node|
        node['performance'] = {}
        node['performance']['core_flops'] =  node['processor']['clock_speed'].to_i * get_flops_per_cycle(node['processor']['microarchitecture'], node['processor']['other_description'])
        node['performance']['node_flops'] = node['architecture']['nb_cores'].to_i * node['performance']['core_flops'].to_i
      end
    end
  end
end

def add_site_ipv6_infos(h)
  global_prefix = IPAddress h['ipv6']['prefix']
  h['sites'].each_pair do |site_uid, hs|
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

