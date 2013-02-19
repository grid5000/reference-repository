# Parse net-links given through @config parameter
# @config parameter contains nothin but net-links yaml configurations

@config.each do |equipment_uid, properties|
  properties = properties[equipment_uid]
  site_name = properties["site"]
  site site_name.to_sym do |site|
    network_equipment equipment_uid do |uid|
      # Most properties are directly written as they are from the net-links YAML file to the the JSON file
      model properties["model"]
      kind properties["kind"]
      @context.recursive_merge!(:site => site)
      snmp_community properties["snmp_community"]
      weathermap properties["weathermap"] || {}
      vlans properties["vlans"]
      routes properties["routes"]
      channels properties["channels"]
      backplane_bps properties["backplane_bps"]

      # Change the format of linecard from Hash to Array
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
