#!/usr/bin/ruby

require 'pp'
require 'erb'
require 'fileutils'
require 'pathname'
require 'json'

require '../lib/input_loader'

# Output directory
refapi_path = "/tmp/data"

#global_hash = JSON.parse(STDIN.read)
global_hash = load_yaml_file_hierarchy("../../input/example/")

# Write pretty and sorted JSON files
def write_json(filepath, data)
  def rec_sort(h)
    case h
    when Array
      h.map{|v| rec_sort(v)}.sort_by!{|v| (v.to_s rescue nil) }
    when Hash
      Hash[Hash[h.map{|k,v| [rec_sort(k),rec_sort(v)]}].sort_by{|k,v| [(k.to_s rescue nil), (v.to_s rescue nil)]}]
    else
      h
    end
  end
  File.open(filepath, 'w') do |f|
    f.write(JSON.pretty_generate(rec_sort(data)))
  end
end

# Parse network equipment description and return switch name and port connected to given node
#  In the network description, if the node interface is given (using "port" attribute),
#  the interface parameter must be used.
def net_switch_port_lookup(site, node_uid, interface='')
  site["network"].each do |switch_uid, switch|
    switch["linecards"].each do |lc_uid,lc|
      lc["ports"].each do |port_uid,port|
        if port.is_a?(Hash)
          switch_remote_port = port["port"] || lc["port"] || ""
          switch_remote_uid = port["uid"]
        else
          switch_remote_port = lc["port"] || ""
          switch_remote_uid = port
        end
        if switch_remote_uid == node_uid and switch_remote_port == interface
            # Build port name from snmp_naming_pattern
            # Example: '3 2 GigabitEthernet%LINECARD%/%PORT%' -> 'GigabitEthernet3/2'
            port_name = lc["snmp_pattern"].sub("%LINECARD%",lc_uid.to_s).sub("%PORT%",port_uid.to_s)
            return switch_uid, port_name
        end
      end
    end
  end
  return nil
end

global_hash["sites"].each do |site_uid, site|

  site["clusters"].each do |cluster_uid, cluster|

    cluster_path = Pathname.new(refapi_path).join("sites",site_uid,"clusters",cluster_uid)
    cluster_path.join("nodes").mkpath()

    # Write cluster info w/o nodes entries
    write_json(cluster_path.join("#{cluster_uid}.json"),
               cluster.reject {|k, v| k == "nodes"})

    # Write node info
    cluster["nodes"].each do |node_uid, node|

      node["uid"] = node_uid

      # Rename keys
      node["storage_devices"] = node.delete("block_devices")
      node["network_adapters"] = node.delete("network_interfaces")
      if node.key?("chassis")
        node["chassis"]["name"]   = node["chassis"].delete("product_name")
        node["chassis"]["serial"] = node["chassis"].delete("serial_number")
      end
      
      # Convert hashes to arrays
      node["storage_devices"] = node["storage_devices"].values
      node["network_adapters"] = node["network_adapters"].values

      # Populate "network_address", "switch" and "port" from the network equipment description for each network adapters
      node["network_adapters"].each { |network_adapter|
        if network_adapter["enabled"]
          if network_adapter["management"]
            # Management network_adapter
            network_adapter["network_address"] = "#{node_uid}-bmc.#{site_uid}.grid5000.fr"
          elsif network_adapter["mounted"]
            # Primary network_adapter
            network_adapter["bridged"] = true
            network_adapter["network_address"] = "#{node_uid}.#{site_uid}.grid5000.fr"
            # Interface may not be specified in Network Reference for primary network_adapter
            network_adapter["switch"], network_adapter["port"] = \
              net_switch_port_lookup(site, node_uid) || net_switch_port_lookup(site, node_uid, network_adapter["device"])
          else
            # Secondary network_adapter(s)
            network_adapter["network_address"] = "#{node_uid}-#{network_adapter["device"]}.#{site}.grid5000.fr"
            network_adapter["switch"], network_adapter["port"] = net_switch_port_lookup(site, node_uid, network_adapter["device"])
          end
        end
      }

      #pp cluster_path.join("nodes","#{node_uid}.json")
      write_json(cluster_path.join("nodes","#{node_uid}.json"), node)
    end
  end
end
