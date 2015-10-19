#!/usr/bin/ruby

require 'pathname'
require 'json'

refapi_path = "/tmp/data"
data = JSON.parse(STDIN.read)

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

data["sites"].each do |site_uid, site|

  site["clusters"].each do |cluster_uid, cluster|

    cluster_path = Pathname.new(refapi_path).join("sites",site_uid,"clusters",cluster_uid)
    cluster_path.join("nodes").mkpath()

    # Write cluster info w/o nodes entries
    write_json(cluster_path.join("#{cluster_uid}.json"),
               cluster.reject {|k, v| k == "nodes"})

    cluster["nodes"].each do |node_uid, node|

      node["uid"] = node_uid

      # TODO: fix inconsistency?
      node["storage_devices"].each {|s| s.update(node["block_devices"].values.at(node["storage_devices"].index(s)))}
      node.delete("block_devices")

      # TODO: fix inconsistency?
      node["chassis"]["name"] = node["chassis"]["product_name"]
      node["chassis"]["serial"] = node["chassis"]["serial_number"]
      node["chassis"].delete("product_name")
      node["chassis"].delete("serial_number")

      # TODO: fix inconsistency?
      node["network_adapters"].each do |iface|
        node["network_interfaces"].select {|k| k.to_s == iface["device"]}.each do |k, v|
          iface.update(v)
        end
      end
      node.delete("network_interfaces")

      # Network Reference
      node["network_adapters"].each do |iface|
        if iface["enabled"]
          if iface["management"]
            # Managment iface
            iface["network_address"] = "#{node_uid}-bmc.#{site_uid}.grid5000.fr"
          elsif iface["mounted"]
            # Primary iface
            iface["bridged"] = true
            iface["network_address"] = "#{node_uid}.#{site_uid}.grid5000.fr"
            # Interface may not be specified in Network Reference for primary iface
            iface["switch"], iface["port"] = \
              net_switch_port_lookup(site, node_uid) || net_switch_port_lookup(site, node_uid, iface["device"])
          else
            # Secondary iface(s)
            iface["network_address"] = "#{node_uid}-#{iface["device"]}.#{site}.grid5000.fr"
            iface["switch"], iface["port"] = net_switch_port_lookup(site, node_uid, iface["device"])
          end
        end
      end

      write_json(cluster_path.join("nodes","#{node_uid}.json"), node)
    end
  end
end
