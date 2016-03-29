#!/usr/bin/ruby

require 'pp'
require 'erb'
require 'fileutils'
require 'pathname'
require 'json'
require 'time'

require '../lib/input_loader'

# Output directory
#refapi_path = "/tmp/data"
refapi_path = "../../data/grid5000"

#global_hash = JSON.parse(STDIN.read)
#global_hash = load_yaml_file_hierarchy("../input/example/")
global_hash = load_yaml_file_hierarchy("../input/grid5000/")

# Parse network equipment description and return switch name and port connected to given node
#  In the network description, if the node interface is given (using "port" attribute),
#  the interface parameter must be used.
def net_switch_port_lookup(site, node_uid, interface='')
  site["networks"].each do |switch_uid, switch|
    #pp switch_uid
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
  pp site_uid
#  pp site

  site["clusters"].each do |cluster_uid, cluster|
    pp cluster_uid

    cluster_path = Pathname.new(refapi_path).join("sites",site_uid,"clusters",cluster_uid)
    cluster_path.join("nodes").mkpath()

    # Write cluster info w/o nodes entries
    cluster["type"] = "cluster"
    cluster["uid"]  = cluster_uid
    
    # On the previous version of this script, cluster["created_ad"] was generated from a Ruby Time. cluster["created_ad"] is now a Ruby Date at JSON import.
    # As Date.httpdate and Time.httpdate does not behave the same with timezone, it is converted here as a Ruby time.
    cluster["created_at"] = Time.parse(cluster["created_at"].to_s).httpdate
    
    write_json(cluster_path.join("#{cluster_uid}.json"),
               cluster.reject {|k, v| k == "nodes"})
    
    # Write node info
    cluster["nodes"].each do |node_uid, node|# _sort_by_node_uid
      pp node_uid

      #pp node if node_uid == "graoully-1"
      #next unless node_uid == "griffon-1"
      
      node["uid"] = node_uid
      node["type"] = "node"
      if node.key?("processor")
        node["processor"]["cache_l1"] ||= nil
      end
      
      # Add default keys
      node["gpu"] = {} unless node.key?("gpu")
      node["gpu"]["gpu"] ||= false
      
      node["main_memory"] = {} unless node.key?("main_memory")
      node["main_memory"]["virtual_size"] ||= nil

      # Delete keys
      node["storage_devices"].keys.each { |key| 
        node["storage_devices"][key].delete("timeread")  if node["storage_devices"][key].key?("timeread")
        node["storage_devices"][key].delete("timewrite") if node["storage_devices"][key].key?("timewrite")
      }
      node.delete("status")

      # Type conversion
      node["network_adapters"].each { |key, hash| hash["rate"] = hash["rate"].to_i if hash["rate"].is_a?(Float) }

      # Convert hashes to arrays
      node["storage_devices"].each { |key, hash| node["storage_devices"][key]["device"] = key; } # Add "device: sdX" within the hash
      node["storage_devices"] = node["storage_devices"].sort_by_array(["sda", "sdb", "sdc", "sdd", "sde"]).values

      node["network_adapters"].each { |key, hash| node["network_adapters"][key]["device"] = key; } # Add "device: ethX" within the hash
      node["network_adapters"] = node["network_adapters"].sort_by_array(["eth0", "eth1", "eth2", "eth3", "eth4", "eth5", "eth6", "ib0", "ib1", "ib2", "ib3", "bmc"]).values

      # Populate "network_address", "switch" and "switch_port" from the network equipment description for each network adapters
      node["network_adapters"].each { |network_adapter|
        network_adapter["mac"] = network_adapter["mac"].downcase if network_adapter["mac"].is_a?(String)

        # infiniband properties
        network_adapter["ib_switch_card"]     = network_adapter.delete("line_card") if network_adapter.key?("line_card")
        network_adapter["ib_switch_card_pos"] = network_adapter.delete("position")  if network_adapter.key?("position")

        if network_adapter["management"]
          # Management network_adapter (bmc)
          network_adapter["network_address"] = "#{node_uid}-bmc.#{site_uid}.grid5000.fr"
        elsif network_adapter["mounted"] and /^eth[0-9]$/.match(network_adapter["device"])
          # Primary network_adapter
          network_adapter["network_address"] = "#{node_uid}.#{site_uid}.grid5000.fr" if network_adapter["enabled"]
         
          # Interface may not be specified in Network Reference for primary network_adapter
          network_adapter["switch"], network_adapter["switch_port"] = net_switch_port_lookup(site, node_uid, network_adapter["device"]) || net_switch_port_lookup(site, node_uid)
        else
          # Secondary network_adapter(s)
          network_adapter["network_address"] = "#{node_uid}-#{network_adapter["device"]}.#{site_uid}.grid5000.fr" if network_adapter["enabled"] && network_adapter["mounted"]
          if network_adapter["mountable"]
            switch, port = net_switch_port_lookup(site, node_uid, network_adapter["device"])
            network_adapter["switch"] = switch if switch
            network_adapter["switch_port"] = port if port
          end
        end
      }

      node["sensors"] ||= {}

      node["monitoring"] = {} unless node.key?("monitoring")
      node["monitoring"]["wattmeter"] ||= false
      node["monitoring"]["wattmeter"] = "true"  if node["monitoring"]["wattmeter"] == true
      node["monitoring"]["wattmeter"] = "false" if node["monitoring"]["wattmeter"] == false
      if (node.key?("pdu") && node["pdu"].key?("pdu_name")) ||
          (node.key?("pdu1") && node["pdu1"].key?("pdu_name"))

        #if cluster_uid == "graphene"
        #  pp "#{pdu_name} #{pdu_position} : #{pdu_info[pdu_name][pdu_position]}"
        #end

#       if pdu_info[pdu_name][pdu_position] == 1
#         node["monitoring"]["wattmeter"] = "true"
#       else
#         node["monitoring"]["wattmeter"] = "shared"
#       end

        node["sensors"]["power"] ||= {}
        node["sensors"]["power"]["available"] = true if node["monitoring"]["wattmeter"] != "false"

        node["sensors"]["power"]["via"] ||= {}
        node["sensors"]["power"]["via"]["pdu"] ||= []
        i=0
        ['pdu', 'pdu1', 'pdu2'].each { |key|
          if (node.key?(key) and node[key].key?("pdu_name"))
            node["sensors"]["power"]["via"]["pdu"][i] ||= {}            
            node["sensors"]["power"]["via"]["pdu"][i]["uid"]  = node[key]["pdu_name"]
            node["sensors"]["power"]["via"]["pdu"][i]["port"] = node[key]["pdu_position"] unless node["monitoring"]["wattmeter"] == "shared"
            node["sensors"]["power"]["via"]["pdu"][i].delete("port") if node["monitoring"]["wattmeter"] == "shared"
            node.delete(key)
            i = i+1
          end
        }
       
        #pp node["monitoring"]["wattmeter"]

        if node["monitoring"]["wattmeter"] == "yes"
          node["sensors"]["power"]["via"]["api"] ||= {}
          node["sensors"]["power"]["via"]["api"]["metric"] = "pdu"
        elsif node["monitoring"]["wattmeter"] != "false"
          node["sensors"]["power"]["via"]["api"] ||= {}
          node["sensors"]["power"]["via"]["api"]["metric"] = "power"
        end

      end

      node.delete("kavlan")

      #pp cluster_path.join("nodes","#{node_uid}.json")
      write_json(cluster_path.join("nodes","#{node_uid}.json"), node)
    end
  end
end
