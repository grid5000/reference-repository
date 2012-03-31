
# Find the net-links yaml file passed as argument
net_links_file = ARGV.find{|a| a.match(/\/net-links.yaml$/) != nil}
if net_links_file.nil?
  @logger.error "Failed to find the net-links.yaml url to guess the site. Please use the file full name."
else
  site_name = File.basename(File.dirname(net_links_file))
  site site_name.to_sym do 
    lookup("net-links").each do |equipment_uid, properties|
      network_equipment equipment_uid do |uid|
        # Most properties are directly written as they are from the net-links YAML file to the the JSON file
        model properties["model"]
        kind properties["kind"]
        snmp_community properties["snmp_community"]
        vlans properties["vlans"]
        routes properties["routes"]
        channels properties["channels"]

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
end

