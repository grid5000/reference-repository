
  site :lille do 
    lookup("net-links").each do |equipment_uid, properties|
      network_equipment equipment_uid do |uid|
        model properties["model"]
        kind properties["kind"]
        snmp_community properties["snmp_community"]
        vlans properties["vlans"]
        routes properties["routes"]
        channels properties["channels"]

        linecards_array = []
        properties["linecards"].each do |linecard_index,linecard|
          ports = []
          linecard.delete("ports").each do |port_index,port|
            port = {"uid"=>port} if port.is_a? String
            ports[port_index] = port
          end
          linecard["ports"] = ports.map{|p| p || {}}
          linecards_array[linecard_index] = linecard
        end
        linecards linecards_array.map{|l| l || {}}
      end
    end
  end
 
