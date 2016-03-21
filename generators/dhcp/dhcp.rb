#!/usr/bin/ruby

require 'pp'
require 'erb'
require 'fileutils'
require '../lib/input_loader'

global_hash = load_yaml_file_hierarchy("../../input/grid5000/")
#puts JSON.generate(data)

# Get the mac and ip of a node. Throw exception if error.
def get_network_info(node_hash, network_interface)
  # Get node_hash["network_adapters"][network_interface]["ip"] and node_hash["network_adapters"][network_interface]["mac"]
  node_network_adapters = node_hash.fetch("network_adapters")
  
  # For the production network, find the mounted interface (either eth0 or eth1)
  neti = network_interface
  if neti == "eth" then
    if node_network_adapters.fetch("eth0").fetch("mounted")
      neti = "eth0"
    elsif node_network_adapters.fetch("eth1").fetch("mounted")
      neti = "eth1"
    else
      raise 'neither eth0 nor eth1 have the property "mounted" set to "true"'
      end
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

  erb = ERB.new(File.read("templates/dhcp.erb"))
  output_file = "output/puppet-repo/modules/dhcpg5k/files/" + data.fetch("site_uid") + "/dhcpd.conf.d/" + data.fetch('filename')

  # Create directory hierarchy
  dirname = File.dirname(output_file)
  FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
  
  # Apply ERB template and save
  File.open(output_file, "w+") { |f|
    f.write(erb.result(binding))
  }
end
 
# Loop over Grid'5000 sites
global_hash["sites"].each { |site_uid, site_hash|
  
  # On file for each clusters
  site_hash.fetch("clusters").each { |cluster_uid, cluster_hash|
    write_dhcp_file({
                      "filename"            => "cluster-" + cluster_uid + ".conf",
                      "site_uid"            => site_uid,
                      "nodes"               => cluster_hash.fetch('nodes'),
                      "network_adapters"  => ["eth", "bmc"],
                    })
  }
  
  # Other dhcp files
  ["networks", "laptops", "dom0"].each { |key|
    write_dhcp_file({
                      "filename"            => key + ".conf",
                      "site_uid"            => site_uid,
                      "nodes"               => site_hash['nodes'],
                      "network_adapters"  => ["eth"],
                    })
  }

}
