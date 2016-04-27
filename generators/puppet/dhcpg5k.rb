#!/usr/bin/ruby

if RUBY_VERSION < "2.1"
  puts "This script requires ruby >= 2.1"
  exit
end

require 'pp'
require 'erb'
require 'pathname'
require '../lib/input_loader'

global_hash = load_yaml_file_hierarchy("../../input/grid5000/")
$output_dir = ENV['puppet_repo'] || '/tmp/puppet-repo'

# Get the mac and ip of a node. Throw exception if error.
def get_network_info(node_hash, network_interface)
  # Get node_hash["network_adapters"][network_interface]["ip"] and node_hash["network_adapters"][network_interface]["mac"]
  node_network_adapters = node_hash.fetch("network_adapters")
  
  # For the production network, find the mounted interface (either eth0 or eth1)
  neti = network_interface
  if neti == "eth" then
    (0..4).each {|i|
      if node_network_adapters.fetch("eth#{i}").fetch("mounted")
        neti = "eth#{i}"
        break
      end
    }
    raise 'none of the eth[0-4] interfaces have the property "mounted" set to "true"' if neti == 'eth'
  end
  
  node_network_interface = node_network_adapters.fetch(neti)
  
  raise '"mac" is nil' unless node_mac = node_network_interface.fetch("mac")
  raise '"ip" is nil'  unless node_ip  = node_network_interface.fetch("ip")
  
  return [node_ip, node_mac]
end

def write_dhcp_file(data)
  if data["nodes"].nil?
    puts "Error in #{__method__}: no entry for \"#{data['filename']}\" at #{data['site_uid']} (#{data['network_adapters']})."
    return "" 
  end

  output = ERB.new(File.read('templates/dhcp.erb')).result(binding)
  output_file = Pathname("#{$output_dir}/modules/dhcpg5k/files/#{data.fetch("site_uid")}/dhcpd.conf.d/#{data.fetch('filename')}")
  output_file.dirname.mkpath()
  File.write(output_file, output)
end
 
# Loop over Grid'5000 sites
global_hash["sites"].each { |site_uid, site_hash|
  puts site_uid
  next if site_uid != 'nancy'

  #
  # eth, bmc and mic0
  #

  # Relocate ip/mac info of MIC
  site_hash.fetch("clusters").each { |cluster_uid, cluster_hash|
    cluster_hash.fetch('nodes').each { |node_uid, node_hash| 
      site_hash.fetch("clusters").each {
        if node_hash['mic'] && node_hash['mic']['ip'] && node_hash['mic']['mac']
          node_hash['network_adapters'] ||= {}
          node_hash['network_adapters']['mic0'] ||= {}
          node_hash['network_adapters']['mic0']['ip']  = node_hash['mic'].delete('ip')
          node_hash['network_adapters']['mic0']['mac'] = node_hash['mic'].delete('mac')
        end
      }
    }
  }

  # One file for each clusters
  site_hash.fetch("clusters").each { |cluster_uid, cluster_hash|
    # networks = ["eth", "bmc"]
    # networks << 'mic0' if cluster_hash['nodes'].values.any? {|x| x['network_adapters']['mic0'] }

    write_dhcp_file({
                      "filename"            => "cluster-" + cluster_uid + ".conf",
                      "site_uid"            => site_uid,
                      "nodes"               => cluster_hash.fetch('nodes'),
                      "network_adapters"    => ["eth", "bmc", "mic0"],
                      "optional_network_adapters"  => ["mic0"]
                    })
  }

  #
  #
  #

  # Other dhcp files
  ["networks", "laptops", "dom0"].each { |key|
    write_dhcp_file({
                      "filename"            => key + ".conf",
                      "site_uid"            => site_uid,
                      "nodes"               => site_hash[key],
                      "network_adapters"    => ["eth", "bmc", "adm"],
                      "optional_network_adapters"  => ["bmc", "adm"]
                    })
  }

  #
  # PDUs
  #

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
  write_dhcp_file({
                    "filename"            => key + ".conf",
                    "site_uid"            => site_uid,
                    "nodes"               => site_hash['pdus'],
                    "network_adapters"  => ['pdu'],
                  })

}
