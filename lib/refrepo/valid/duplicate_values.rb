require 'refrepo/data_loader'
def check_duplicate_values
  netifs = []
  refapi = load_data_hierarchy
  refapi['sites'].each_pair do |site_uid, site|
    site['clusters'].each_pair do |cluster_uid, cluster|
      cluster['nodes'].to_h.each do |node_uid, node|
        node['network_adapters'].each do |na|
          # we ignore interface that are not enabled, mounted, mountable or management
          next unless na['enabled'] or na['mounted'] or na['mountable'] or na['management']

          netifs << { site: site_uid,
                      cluster: cluster_uid,
                      node: node_uid,
                      iface: na['name'],
                      ip: na['ip'],
                      ip6: na['ip6'],
                      mac: na['mac'].downcase,
                      enabled: na['enabled'],
                      mounted: na['mounted'],
                      mountable: na['mountable'],
                      management: na['management'] }
        end
      end
    end
  end

  ret = true

  dupe_macs = netifs.group_by { |e| e[:mac] }.to_a.select { |e| e[1].length > 1 }
  unless dupe_macs.empty?
    ret = false
    dupe_macs.each do |e|
      puts "ERROR: MAC #{e[0]} is used by several nodes:"
      puts e[1].map { |n| n.to_s }.join("\n")
    end
  end

  dupe_ips = netifs.select { |e| e[:ip] }.group_by { |e| e[:ip] }.to_a.select { |e| e[1].length > 1 }
  unless dupe_ips.empty?
    ret = false
    dupe_ips.each do |e|
      puts "ERROR: IP #{e[0]} is used by several nodes:"
      puts e[1].map { |n| n.to_s }.join("\n")
    end
  end

  dupe_ip6s = netifs.select { |e| e[:ip6] }.group_by { |e| e[:ip6] }.to_a.select { |e| e[1].length > 1 }
  unless dupe_ips.empty?
    ret = false
    dupe_ip6s.each do |e|
      puts "ERROR: IPv6 #{e[0]} is used by several nodes:"
      puts e[1].map { |n| n.to_s }.join("\n")
    end
  end

  ret
end
