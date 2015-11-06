#!/usr/bin/ruby

require 'pp'
require 'erb'
require 'fileutils'
require '../lib/input_loader'

global_hash = load_yaml_file_hierarchy("../../input/grid5000/")
#puts JSON.generate(data)

# Loop over a node list (hash_of_nodes) and return the corresponding dhcp entries
def dhcp_node_entries(site_uid, hash_of_nodes, network_interface, description_string=nil, hostname=true)
  if hash_of_nodes.nil?
    puts "Error in #{__method__}: no entry for \"#{description_string}\" at #{site_uid} (#{network_interface})."
    return "" 
  end

  StringIO.open { |s|
    
    if description_string
      s << '##################################################' << "\n"
      s << "### " << description_string << "\n"
      s << '##################################################' << "\n\n"
    end

    # For each node (sorted by #name, #id) 
    hash_of_nodes.sort_by { |item| item.to_s.split(/(\d+)/).map { |e| [e.to_i, e] } }.each { |node_uid, node_hash|
      s << dhcp_node_entry(site_uid, node_uid, node_hash, network_interface, hostname)
    }
    s.string

  }
end 

# Print the DHCP entry of a node :
#
# host node_uid_net.site_uid.grid5000.fr {
#   hardware ethernet       00:E0:81:D5:06:B8;
#   fixed-address           172.16.64.144;
#   option host-name        "node_uid_net";
# }
def dhcp_node_entry(site_uid, node_uid, node_hash, network_interface, hostname=true)
  node_uid_net = node_uid
  node_uid_net = node_uid + "-bmc" if network_interface == "bmc"

  # Get node_hash["network_interfaces"][network_interface]["ip"] and node_hash["network_interfaces"][network_interface]["mac"]
  begin
    node_network_interfaces = node_hash.fetch("network_interfaces")

    # For the production network, find the mounted interface (either eth0 or eth1)
    neti = network_interface
    if neti == "eth" then
      if node_network_interfaces.fetch("eth0").fetch("mounted")
        neti = "eth0"
      elsif node_network_interfaces.fetch("eth1").fetch("mounted")
        neti = "eth1"
      else
        raise 'neither eth0 nor eth1 have the property "mounted" set to "true"'
      end
    end
    
    node_network_interface = node_network_interfaces.fetch(neti)
    
    raise '"mac" is nil' unless node_mac = node_network_interface.fetch("mac")
    raise '"ip" is nil'  unless node_ip  = node_network_interface.fetch("ip")

  rescue => e
    # Hash.fetch(key) raise KeyError if the hash[key] does not exist.
    puts "Error in #{__method__}: #{e}. Skip the DHCP entry for #{node_uid} at #{site_uid} (#{network_interface})."
    return ""
  end

  StringIO.open { |s|
    s << 'host ' + node_uid_net + '.' + site_uid + '.grid5000.fr {' << "\n"
    s << '  hardware ethernet       '  + node_mac.upcase + ';'  << "\n"
    s << '  fixed-address           '  + node_ip         + ';'  << "\n"
    s << '  option host-name        "' + node_uid_net    + '";' << "\n" if hostname
    s << '}' << "\n\n"
    
    s.string
  }

end

def write_dhcp_file(site_uid, hash_of_nodes, network_interfaces, output_filename, description_string=nil, hostname=true)
  erb = ERB.new(File.read("templates/dhcp.erb"))
  output_file = "output/puppet-repo/modules/dhcpg5k/files/" + site_uid + "/dhcpd.conf.d/" + output_filename + ".conf"

  pp output_file

  # Create directory hierarchy
  dirname = File.dirname(output_file)
  FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
  
  # Apply ERB template and save
  File.open(output_file, "w+") { |f|
    network_interfaces.each { |network_interface|
      f << dhcp_node_entries(site_uid, hash_of_nodes, network_interface, description_string, hostname)
    }
  }
end
 
# Loop over Grid'5000 sites
global_hash["sites"].each { |site_uid, site_hash|
  
  # On file for each clusters
  site_hash.fetch("clusters").each { |cluster_uid, cluster_hash|
    write_dhcp_file(site_uid, cluster_hash["nodes"], ["eth", "bmc"], "cluster-" + cluster_uid, description_string=nil, hostname=true)
  }
  
  # Other dhcp files
  write_dhcp_file(site_uid, site_hash["net-links"], "eth", "switchs", "Switchs", false)
  write_dhcp_file(site_uid, site_hash["laptops"],   "eth", "laptops", "Admin laptop's")
  write_dhcp_file(site_uid, site_hash["dom0"],      "eth", "dom0",    "Dom0")
}


