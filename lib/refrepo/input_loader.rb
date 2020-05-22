# Load a hierarchy of YAML file into a Ruby hash

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

  # populate each node with its IPv6
  add_ipv6(global_hash)

  # populate each node with its IPv4 addresses
  add_ipv4(global_hash)

  # populate each node with its kavlan IPv4 IPs
  add_kavlan_ips(global_hash)
  add_kavlan_ipv6s(global_hash)

  # populate each node with software informations
  add_software(global_hash)

  # populate each cluster with metrics network information
  add_network_metrics(global_hash)

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
            ip6 = '2001:660:4406:'
            ip6 += '%x' % h['ipv6']['site-indexes'][site_uid]
            ip6 += '00:'
            ip6 += '%x' % ((ip4.split('.')[2].to_i & 0b1111) + 1)
            if idx > 0
              ip6 += ':%x::' % idx
            else
              ip6 += '::'
            end
            ip6 += '%x' % (ip4.split('.')[3].to_i)
            nah['ip6'] = ip6
          end
        end
      end
    end
  end
end

def add_kavlan_ipv6s(h)
  h['sites'].each_pair do |site_uid, hs|
    hs['clusters'].each_pair do |_cluster_uid, hc|
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
              ip6 = '2001:660:4406:'
              ip6 += '%x' % h['ipv6']['site-indexes'][site_uid]
              ip6 += '%x:' % (kvl_id + 0x80)
              ip6 += '%x' % ((ip4.split('.')[2].to_i & 0b1111) + 1)
              if idx > 0
                ip6 += ':%x::' % idx
              else
                ip6 += '::'
              end
              ip6 += '%x' % (ip4.split('.')[3].to_i)
              hn['kavlan6'][iface]["kavlan-#{kvl_id}"] = ip6
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
      node_uid, node = cluster['nodes'].select { |k, v| v['status'] != 'retired' }.first
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
