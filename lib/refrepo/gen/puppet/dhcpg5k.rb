# Get the mac, ipv4, ipv6 of a node. Throw exception if error.
def get_network_info(node_hash, network_interface)
  # Get node_hash["network_adapters"][network_interface]["ip"], node_hash["network_adapters"][network_interface]["ip6"] and node_hash["network_adapters"][network_interface]["mac"]
  node_network_adapters = node_hash.fetch("network_adapters")

  # For the production network, find the mounted interface (either eth0 or eth1)
  neti = network_interface
  if neti == "eth" then
    neti = node_network_adapters.select { |i| i['device'] =~ /eth/ and i['mounted'] }[0]['device']
    unless neti
      raise 'none of the eth[0-4] interfaces have the property "mounted" set to "true"' if neti == 'eth'
    end
  end

  node_network_interface = nil
  case node_network_adapters
  when Array
    node_network_interface = node_network_adapters.select { |i| i['device'] == neti }[0]
  when Hash
    node_network_interface = node_network_adapters[neti]
  end

  node_mac = node_network_interface.fetch('mac')
  node_ipv4 = node_network_interface.fetch('ip')
  node_ipv6 = node_network_interface.fetch('ip6', nil)

  raise '"mac" is nil'  unless node_mac
  raise '"ip" is nil'   unless node_ipv4
  #raise '"ipv6" is nil' unless node_ipv6 # commented right now, we don't yet impose ipv6 for everything

  return [node_ipv4, node_ipv6, node_mac]
end

def write_dhcp_files(data, options)
  if data["nodes"].nil?
    puts "Error in #{__method__}: no entry for \"#{data['filename']}\" at #{data['site_uid']} (#{data['network_adapters']})."
    return ""
  end

  ["dhcp", "dhcpv6"].each { |dhcpkind|
    output = ERB.new(File.read(File.expand_path("templates/dhcp.erb", File.dirname(__FILE__)))).result(binding)
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
