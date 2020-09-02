# Get the mac, ipv4, ipv6 of a node. Throw exception if error.
def get_network_info(node_hash, network_interface)
  node_network_adapters = node_hash.fetch("network_adapters")

  network_infos = []
  if network_interface == "eth" then
    adapters = node_network_adapters.select { |i| i['device'] =~ /eth/ and (i['mountable'] or i['mounted'])}
    if adapters.length > 0
      if not adapters[0]['mounted']
        raise "#{node_hash['uid']}: inconsistency: this code assumes first mountable ethernet adapter should be mounted: #{node_network_adapters}"
      end
    end
  else
    case node_network_adapters
    when Array
      adapters = node_network_adapters.select { |i| i['device'] == network_interface }
    when Hash
      adapters = [ node_network_adapters[network_interface] ]
    end
  end
  if adapters.length > 0
    for a in adapters
      mac = a.fetch('mac')
      ip = a.fetch('ip', nil)
      ip6 = a.fetch('ip6', nil)
      name = a.fetch('network_address').split('.')[0] rescue node_hash['uid']
      if (not ip.nil?) or (not ip6.nil?)
        network_infos << {'mac' => mac,
                          'name' => name,
                          'ip' => ip,
                          'ip6' => ip6 }
      end
    end
  end
  return network_infos
end

def write_dhcp_files(data, options)
  if data["nodes"].nil?
    puts "Error in #{__method__}: no entry for \"#{data['filename']}\" at #{data['site_uid']} (#{data['network_adapters']})."
    return ""
  end

  ["dhcp", "dhcpv6"].each { |dhcpkind|
    output = ERB.new(File.read(File.expand_path("templates/dhcp.erb", File.dirname(__FILE__))), nil, '-').result(binding)
    output_file = Pathname("#{options[:output_dir]}/platforms/production/modules/generated/files/grid5000/#{dhcpkind}/#{data.fetch("site_uid")}/#{data.fetch('filename')}")
    output_file.dirname.mkpath()
    File.write(output_file, output)
  }
end

def generate_puppet_dhcpg5k(options)
  global_hash = load_data_hierarchy

  puts "Writing DHCP configuration files to: #{options[:output_dir]}"
  puts "For site(s): #{options[:sites].join(', ')}"

  # Loop over Grid'5000 sites
  global_hash["sites"].each { |site_uid, site_hash|

    next unless options[:sites].include?(site_uid)

    puts site_uid

    #
    # eth, bmc and mic0
    #

    # Relocate ip/mac info of MIC
    site_hash.fetch("clusters").each { |cluster_uid, cluster_hash|
      cluster_hash.fetch('nodes').each { |node_uid, node_hash|
        next if node_hash == nil || node_hash['status'] == 'retired'

        if node_hash['mic'] && node_hash['mic']['ip'] && node_hash['mic']['mac']
          node_hash['network_adapters'] ||= []
          node_hash['network_adapters'].push({
                                               'device' => 'mic0',
                                               'ip'=> node_hash['mic'].delete('ip'),
                                               'mac' => node_hash['mic'].delete('mac')
                                             })
        end
      }
    }

    # One file for each clusters
    site_hash.fetch("clusters").each { |cluster_uid, cluster_hash|
      # networks = ["eth", "bmc"]
      # networks << 'mic0' if cluster_hash['nodes'].values.any? {|x| x['network_adapters']['mic0'] }
      write_dhcp_files({
        "filename"            => "cluster-" + cluster_uid + ".conf",
        "site_uid"            => site_uid,
        "nodes"               => cluster_hash.fetch('nodes'),
        "network_adapters"    => ["eth", "bmc", "mic0"],
        "optional_network_adapters"  => ["mic0"]
      }, options)
    }


    # Other dhcp files
    ["networks", "laptops", "servers"].each { |key|
      write_dhcp_files({
        "filename"            => key + ".conf",
        "site_uid"            => site_uid,
        "nodes"               => site_hash[key],
        "network_adapters"    => ["default", "eth", "bmc", "adm"],
        "optional_network_adapters"  => ["eth", "bmc", "adm"]
      }, options) unless site_hash[key].nil?
    }

    #
    # PDUs
    #

    if ! site_hash['pdus'].nil?
      # Relocate ip/mac info of PDUS
      site_hash['pdus'].each { |pdu_uid, pdu_hash|
        if pdu_hash['ip'] && pdu_hash['mac']
          pdu_hash['network_adapters'] ||= {}
          pdu_hash['network_adapters']['pdu'] ||= {}
          pdu_hash['network_adapters']['pdu']['ip']  = pdu_hash.delete('ip')
          pdu_hash['network_adapters']['pdu']['mac'] = pdu_hash.delete('mac')
        end
      }

      key = 'pdus'
      write_dhcp_files({
        "filename"            => key + ".conf",
        "site_uid"            => site_uid,
        "nodes"               => site_hash['pdus'],
        "network_adapters"  => ['pdu'],
        "optional_network_adapters"  => []
      }, options)
    end

  }
end
