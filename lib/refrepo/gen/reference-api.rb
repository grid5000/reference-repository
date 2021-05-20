require 'refrepo/valid/input/schema'
require 'refrepo/valid/homogeneity'

# Creation du fichier network_equipment
def create_network_equipment(network_uid, network, refapi_path, site_uid = nil)
  network["type"] = "network_equipment"
  network["uid"]  = network_uid

  network_path = ''
  if site_uid
    network_path = Pathname.new(refapi_path).join("sites", site_uid, "network_equipments")
  else
    network_path = Pathname.new(refapi_path).join("network_equipments")
  end
  network_path.mkpath()

  # Change the format of linecard from Hash to Array
  linecards_tmp = Marshal.load(Marshal.dump(network["linecards"])) # bkp (deep_copy)

  linecards_array = []
  network["linecards"].each do |linecard_index, linecard|
    ports = []
    linecard.delete("ports").each do |port_index, port|
      port = { "uid"=> port } if port.is_a? String
      if port.is_a? Hash
        # complete entries (see bug 8587)
        if port['port'].nil? and linecard['port']
          port['port'] = linecard['port']
        end
        if port['kind'].nil? and linecard['kind']
          port['kind'] = linecard['kind']
        end
        if port['snmp_pattern'].nil? and linecard['snmp_pattern']
          port['snmp_pattern'] = linecard['snmp_pattern']
        end
        if port['snmp_pattern']
          port['snmp_name'] = port['snmp_pattern']
            .sub('%LINECARD%',linecard_index.to_s).sub('%PORT%',port_index.to_s)
          port.delete('snmp_pattern')
        end
        if ((!linecard['kind'].nil? &&
            port['kind'].nil? &&
            linecard['kind'] == 'node') ||
            port['kind'] == 'node') &&
            port['port'].nil?
          p = port['uid'].match(/([a-z]*-[0-9]*)-?(.*)/).captures[1]
          port['port'] = p != '' ? p : 'eth0'
          port['uid'] = port['uid'].gsub(/-#{p}$/, '')
        end
      end
      ports[port_index] = port
    end
    linecard["ports"] = ports.map { |p| p || {} }
    linecards_array[linecard_index] = linecard
  end
  network["linecards"] = linecards_array.map{|l| l || {}}

  network.delete_if {|k, v| k == "network_adapters"} # TO DELETE

  write_json(network_path.join("#{network_uid}.json"), network)

  network["linecards"] = linecards_tmp # restore
end

def generate_reference_api
  # Output directory
  output_data_dir = "../../../data/grid5000/"

  refapi_path = File.expand_path(output_data_dir, File.dirname(__FILE__))
  global_hash = load_yaml_file_hierarchy

  #
  # Write grid info
  #

  if global_hash['uid']
    global_hash["type"] = "grid"

    # remove kavlan information for now
    global_hash.delete('vlans')
    # remove software info
    global_hash.delete('software')
    # remove ipv4 info
    global_hash.delete('ipv4')
    # remove ipv6 info
    global_hash.delete('ipv6')
    
    grid_path = Pathname.new(refapi_path)
    grid_path.mkpath()

    write_json(grid_path.join("#{global_hash['uid']}.json"),
               global_hash.reject {|k, v| k == "sites" || k == "network_equipments" || k == "disk_vendor_model_mapping"})
  end

  puts "Generating the reference api:\n\n"
  puts "Removing data directory:\n"
  FileUtils.rm_rf(Pathname.new(refapi_path).join("sites"))
  FileUtils.rm_rf(Pathname.new(refapi_path).join("network_equipments"))
  puts "Done."

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

      pdu_attached_nodes = {}
      site.fetch("clusters", []).sort.each do |cluster_uid, cluster|
        cluster["nodes"].each do |node_uid, node|# _sort_by_node_uid
          next if node['status'] == "retired"
          node.fetch('pdu', []).each do |node_pdu|
            if node_pdu["uid"] == pdu_uid
              pdu_attached_nodes[node_pdu["port"]] = node_uid
            end
          end
        end
      end
      pdu["ports"] = pdu_attached_nodes

      write_json(pdu_path.join("#{pdu_uid}.json"), pdu)
    end if site.key?("pdus")

    #
    # Write servers info
    #

    servers_path = site_path.join("servers")
    servers_path.mkpath()
    if site.key?("servers")
      site["servers"].each do |server_uid, server|
        write_json(servers_path.join("#{server_uid}.json"), server)
      end
    end

    #
    # Write network info
    #

    site.fetch("networks", []).sort.each do |network_uid, network|
      create_network_equipment(network_uid, network, refapi_path, site_uid)
    end

    site.fetch("clusters", []).sort.each do |cluster_uid, cluster|
      puts "  #{cluster_uid}"

      #
      # Write cluster info
      #

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

        next if node['status'] == "retired"

        node.delete("status")

        # Convert hashes to arrays
        Hash(node["storage_devices"]).each { |key, hash| node["storage_devices"][key]["device"] = key; } # Add "device: sdX" within the hash
        node["storage_devices"] = Hash(node["storage_devices"]).sort_by_array(["sda", "sdb", "sdc", "sdd", "sde", "sdf", "nvme0n1", "nvme1n1"]).values

        node["network_adapters"].each { |key, hash| node["network_adapters"][key]["device"] = key; } # Add "device: ethX" within the hash
        node["network_adapters"] = node["network_adapters"].sort_by_array(["eth0", "eth1", "eth2", "eth3", "eth4", "eth5", "eth6", "ib0.8100", "ib0", "ib1", "ib2", "ib3", "ibs1","bmc", "eno1", "eno2", "eno1np0", "eno2np1", "ens4f0", "ens4f1", "ens5f0", "ens5f1"]).values

        write_json(cluster_path.join("nodes","#{node_uid}.json"), node)
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

  # Write global json file - Disable this for now, see https://www.grid5000.fr/w/TechTeam:CT-220
  #write_json(grid_path.join(File.expand_path("../../#{global_hash['uid']}-all.json", File.dirname(__FILE__))), global_hash)
end
