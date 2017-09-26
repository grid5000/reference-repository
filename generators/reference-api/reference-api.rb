#!/usr/bin/ruby

if RUBY_VERSION < "2.1"
  puts "This script requires ruby >= 2.1"
  exit
end

require 'pp'
require 'optparse'
require 'erb'
require 'fileutils'
require 'pathname'
require 'json'
require 'time'

require_relative '../lib/input_loader'
require_relative '../input-validators/yaml-input-schema-validator'
require_relative '../input-validators/check-cluster-homogeneity'
require_relative '../input-validators/check-monitoring-properties'

# Output directory
input_data_dir = "../../input/grid5000/"
output_data_dir = "../../data/grid5000/"

refapi_path = File.expand_path(output_data_dir, File.dirname(__FILE__))
global_hash = load_yaml_file_hierarchy(File.expand_path(input_data_dir, File.dirname(__FILE__)))

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

# Creation du fichier network_equipment
def create_network_equipment(network_uid, network, refapi_path, site_uid=nil)
  network["type"] = "network_equipment"
  network["uid"]  = network_uid

  network_path = ''
  if site_uid
    network_path = Pathname.new(refapi_path).join("sites", site_uid, "network_equipments")
  else
    network_path = Pathname.new(refapi_path).join("network_equipments")
  end
  network_path.mkpath()

  network["weathermap"] ||= {}

  # Change the format of linecard from Hash to Array
  linecards_tmp = Marshal.load(Marshal.dump(network["linecards"])) # bkp (deep_copy)

  linecards_array = []
  network["linecards"].each do |linecard_index, linecard|
    ports = []
    linecard.delete("ports").each do |port_index, port|
      port = {"uid"=>port} if port.is_a? String
      ports[port_index] = port
    end
    linecard["ports"] = ports.map{|p| p || {}}
    linecards_array[linecard_index] = linecard
  end
  network["linecards"] = linecards_array.map{|l| l || {}}

  network.delete_if {|k, v| k == "network_adapters"}

  write_json(network_path.join("#{network_uid}.json"), network)

  network["linecards"] = linecards_tmp # restore
end

OptionParser.new do |opts|
  opts.banner = "Usage: reference-api.rb"
  opts.separator ""
  opts.separator "This script generates the reference-api JSON (data/) from the input files (input/)."
  opts.separator "It does not have any option."
  opts.separator ""

  # Print an options summary.
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

#
# Write grid info
#

if global_hash['uid']
  global_hash["type"] = "grid"
  grid_path = Pathname.new(refapi_path)
  grid_path.mkpath()

  write_json(grid_path.join("#{global_hash['uid']}.json"), 
             global_hash.reject {|k, v| k == "sites" || k == "network_equipments"})
end

puts "Generating the reference api:\n\n"

# Generate global network_equipments (renater links)
global_hash["network_equipments"].each do |network_uid, network|
  create_network_equipment(network_uid, network, refapi_path)
end

global_hash["sites"].each do |site_uid, site|
  puts "#{site_uid}:"

  #
  # Write site info
  #

  site["type"] = "site"
  site["uid"]  = site_uid

  #Move special entry "kavlan_topo"
  if site["kavlan_topo"]
    site["kavlans"]["topo"] = site.delete("kavlan_topo")
  end

  site_path = Pathname.new(refapi_path).join("sites", site_uid)
  site_path.mkpath()

  write_json(site_path.join("#{site_uid}.json"), 
             site.reject {|k, v| k == "clusters" || k == "networks" || k == "pdus" || k == "dom0" || k == "laptops" || k == "servers" })

  #
  # Write pdu info
  #

  pdu_path = site_path.join("pdus")
  pdu_path.mkpath()
  site["pdus"].each do |pdu_uid, pdu|
    pdu["type"] = "pdu"
    pdu["uid"]  = pdu_uid
    write_json(pdu_path.join("#{pdu_uid}.json"), pdu)
  end if site.key?("pdus")

  #
  # Write servers info
  #

  servers_path = site_path.join("servers")
  servers_path.mkpath()
  site["servers"].each do |server_uid, server|
    server["type"]  = "server"
    server["uid"]  = server_uid
    write_json(servers_path.join("#{server_uid}.json"), server)
  end if site.key?("servers")

  #
  # Write network info
  #

  site["networks"].sort.each do |network_uid, network|
    create_network_equipment(network_uid, network, refapi_path, site_uid)
  end

  site["clusters"].sort.each do |cluster_uid, cluster|
    puts "  #{cluster_uid}"

    #
    # Write cluster info
    #

    cluster["type"] = "cluster"
    cluster["uid"]  = cluster_uid
    
    # On the previous version of this script, cluster["created_ad"] was generated from a Ruby Time. cluster["created_ad"] is now a Ruby Date at JSON import.
    # As Date.httpdate and Time.httpdate does not behave the same with timezone, it is converted here as a Ruby time.
    cluster["created_at"] = Time.parse(cluster["created_at"].to_s).httpdate

    cluster_path = Pathname.new(refapi_path).join("sites", site_uid, "clusters", cluster_uid)
    cluster_path.mkpath()
    
    # Write cluster info w/o nodes entries
    write_json(cluster_path.join("#{cluster_uid}.json"),
               cluster.reject {|k, v| k == "nodes"})
    
    #
    # Write node info
    #

    cluster_path.join("nodes").mkpath()

    cluster["nodes"].each do |node_uid, node|# _sort_by_node_uid
      begin
      #puts node_uid

      next if node['status'] == "retired"
      
      node["uid"] = node_uid
      node["type"] = "node"
      if node.key?("processor")
        node["processor"]["cache_l1"] ||= nil
      end
      
      # Add default keys
      node["gpu"] = {} unless node.key?("gpu")
      node["gpu"]["gpu"] ||= false
      
      node["main_memory"] = {} unless node.key?("main_memory")

      # Delete keys
      #raise 'node["storage_devices"] is nil' if node["storage_devices"].nil?
      Hash(node["storage_devices"]).keys.each { |key| 
        node["storage_devices"][key].delete("timeread")  if node["storage_devices"][key].key?("timeread")
        node["storage_devices"][key].delete("timewrite") if node["storage_devices"][key].key?("timewrite")
      }
      node.delete("status")

      # Type conversion
      node["network_adapters"].each { |key, hash| hash["rate"] = hash["rate"].to_i if hash["rate"].is_a?(Float) }

      # Convert hashes to arrays
      Hash(node["storage_devices"]).each { |key, hash| node["storage_devices"][key]["device"] = key; } # Add "device: sdX" within the hash
      node["storage_devices"] = Hash(node["storage_devices"]).sort_by_array(["sda", "sdb", "sdc", "sdd", "sde"]).values

      node["network_adapters"].each { |key, hash| node["network_adapters"][key]["device"] = key; } # Add "device: ethX" within the hash
      node["network_adapters"] = node["network_adapters"].sort_by_array(["eth0", "eth1", "eth2", "eth3", "eth4", "eth5", "eth6", "ib0", "ib1", "ib2", "ib3", "bmc"]).values

      # For each network adapters, populate "network_address", "switch" and "switch_port" from the network equipment description
      node["network_adapters"].each { |network_adapter|
        network_adapter["mac"] = network_adapter["mac"].downcase if network_adapter["mac"].is_a?(String)

        # infiniband properties
        network_adapter["ib_switch_card"]     = network_adapter.delete("line_card") if network_adapter.key?("line_card")
        network_adapter["ib_switch_card_pos"] = network_adapter.delete("position")  if network_adapter.key?("position")

        if network_adapter["management"]
          # Management network_adapter (bmc)
          network_adapter["network_address"] = "#{node_uid}-bmc.#{site_uid}.grid5000.fr" unless network_adapter.key?("network_address")
        elsif network_adapter["mounted"] and /^eth[0-9]$/.match(network_adapter["device"])
          # Primary network_adapter
          network_adapter["network_address"] = "#{node_uid}.#{site_uid}.grid5000.fr" if network_adapter["enabled"]
         
          # Interface may not be specified in Network Reference for primary network_adapter
          network_adapter["switch"], network_adapter["switch_port"] = net_switch_port_lookup(site, node_uid, network_adapter["device"]) || net_switch_port_lookup(site, node_uid)
        else
          # Secondary network_adapter(s)
          network_adapter["network_address"] = "#{node_uid}-#{network_adapter["device"]}.#{site_uid}.grid5000.fr" if network_adapter["mountable"] && !network_adapter.key?("network_address")
          if network_adapter["mountable"] || cluster_uid == 'grimoire'
            # || cluster_uid == 'grimoire' is a temporary hack. See #6757
            switch, port = net_switch_port_lookup(site, node_uid, network_adapter["device"])
            network_adapter["switch"] = switch if switch
            network_adapter["switch_port"] = port if port
          end
        end
        # If kavlan entry is not defined here, set it node's kavlan description
        network_adapter["kavlan"] ||= node["kavlan"].keys.include?(network_adapter["device"]) ? true : false

        network_adapter.delete("network_address") if network_adapter["network_address"] == 'none'
      }

      node["sensors"] ||= {}

      node["monitoring"] ||= {}
      node["monitoring"]["wattmeter"] ||= false # default

      # Use strings instead of boolean as possible values are: true/false/shared/etc.
      node["monitoring"]["wattmeter"] = "true"  if node["monitoring"]["wattmeter"] == true
      node["monitoring"]["wattmeter"] = "false" if node["monitoring"]["wattmeter"] == false

      if node.key?("pdu")

        node["pdu"].each { |p|
          pdu = [p].flatten
          pdu.each { |item|
            #See https://intranet.grid5000.fr/bugzilla/show_bug.cgi?id=7585, workaround to validate node pdu that have per_outlets = false
            item.delete("port") if item["port"] == "disabled"
            # Remove 'port' info if PDU are shared
            item.delete("port") if node["monitoring"]["wattmeter"] == "shared"
          }
        }

        # Move PDU info in the right place
        node["sensors"]["power"] ||= {}
        node["sensors"]["power"]["via"] ||= {}
        node["sensors"]["power"]["via"]["pdu"] = node.delete("pdu")
      end # node.key?("pdu")

      if node["monitoring"].key?("metric")
        node["sensors"]["power"] ||= {}
        node["sensors"]["power"]["available"] = true
        node["sensors"]["power"]["via"] ||= {}
        node["sensors"]["power"]["via"]["api"] ||= {}
        node["sensors"]["power"]["via"]["api"]["metric"] = node["monitoring"].delete("metric")
      end


      write_json(cluster_path.join("nodes","#{node_uid}.json"), node)

      rescue => e
        puts "Error while processing #{node_uid}: #{e}"
        raise
      end
    end
  end

end

#
# Write the all-in-one json file
#

# rename entry for the all-in-on json file
global_hash["sites"].each do |site_uid, site|
  site["network_equipments"] = site.delete("networks")
end

#Write global json file
write_json(grid_path.join(File.expand_path("../../#{global_hash['uid']}-all.json", File.dirname(__FILE__))), global_hash)
