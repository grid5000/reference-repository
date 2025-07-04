require 'refrepo/valid/input/schema'
require 'refrepo/valid/homogeneity'
require 'refrepo/accesses'

# Creation du fichier network_equipment
def create_network_equipment(network_uid, network, refapi_path, site_uid = nil)
  network_path = ''
  if site_uid
    network_path = Pathname.new(refapi_path).join("sites", site_uid, "network_equipments")
  else
    network_path = Pathname.new(refapi_path).join("network_equipments")
  end
  network_path.mkpath()

  write_json(network_path.join("#{network_uid}.json"), network)
end

def gen_node_description(node)
  nb_cpu        = node['architecture']['nb_procs'].to_i
  core_per_cpu  = node['architecture']['nb_cores'].to_i / nb_cpu
  ram           = (node['main_memory']['ram_size'].to_i.to_f / (1024**3).to_f).round
  pmem          = (node['main_memory']['pmem_size'].to_i.to_f / (1024**3).to_f).round if node['main_memory']['pmem_size']
  proc_model    = node['processor']['model']
  proc_version  = node['processor']['version']
  if node.key?('gpu_devices')
    nb_gpu       = node['gpu_devices'].length
    gpu_model    = node['gpu_devices'].first[1]['model']
  end
  na            = {}
  net_int       = node['network_adapters']
  net_int.select {
    |int| int['mountable']
  }.each { |i|
    if na.key?((i['rate'] / 1_000_000_000).to_s + 'Gb ' + i['interface'])
      na[(i['rate'] / 1_000_000_000).to_s + 'Gb ' + i['interface']] += 1
    else
      na[(i['rate'] / 1_000_000_000).to_s + 'Gb ' + i['interface']] = 1
    end
  }
  storages = {}
  node['storage_devices'].each do |device|
    unless device['storage'].nil?
      storages[device['storage']].nil? ? storages[device['storage']] = [(device['size'].to_i / 1024**3).round] : storages[device['storage']] += [(device['size'].to_i / 1024**3).round]
    end
  end # each storage
  cluster_storages = ''
  storages.each do |t, s|
    sizes = Hash.new(0)
    s.each { |v| sizes.store(v, sizes[v]+1) }
    sizes.each do |size, nb|
      if nb > 1
        cluster_storages += " #{nb}x#{size}GB #{t},"
      else
        cluster_storages += " #{size}GB #{t},"
      end
    end # each size
  end # each storage
  cluster_storages = cluster_storages[0..-2]
  pmem_message = pmem ? ", #{pmem}GB PMEM" : ''
  gpu_message  = nb_gpu ? ", #{nb_gpu} GPU#{nb_gpu > 1 ? "s" : ""} #{gpu_model}" : ''
  return "#{nb_cpu} CPU#{(nb_cpu > 1) ? "s" : ""} #{proc_model} #{proc_version}, #{core_per_cpu} core#{(core_per_cpu > 1) ? "s" : ""}/CPU#{gpu_message}, #{ram}GB RAM#{pmem_message},#{cluster_storages}, #{na.map { |k,v| "#{v} x #{k}" }.join(', ') }"
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
    # remove management_tools info
    global_hash.delete('management_tools')
    # remove accesses
    global_hash.delete('access')

    grid_path = Pathname.new(refapi_path)
    grid_path.mkpath()

    write_json(grid_path.join("#{global_hash['uid']}.json"),
               global_hash.reject {|k, _v| k == "sites" || k == "network_equipments" || k == "disk_vendor_model_mapping"})
  end

  accesses_path = Pathname.new(refapi_path).join("accesses")

  puts "Generating the reference api:\n\n"
  puts "Removing data directory:\n"

  FileUtils.rm_rf(Pathname.new(refapi_path).join("sites"))
  FileUtils.rm_rf(Pathname.new(refapi_path).join("network_equipments"))
  FileUtils.rm_rf(accesses_path)
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

    site_path = Pathname.new(refapi_path).join("sites", site_uid)
    site_path.mkpath()

    write_json(site_path.join("#{site_uid}.json"),
               site.reject {|k, _v| k == "clusters" || k == "networks" || k == "pdus" || k == "dom0" || k == "laptops" || k == "servers" })

    #
    # Write pdu info
    #

    pdu_path = site_path.join("pdus")
    pdu_path.mkpath()
    site.fetch("pdus", []).each do |pdu_uid, pdu|
      write_json(pdu_path.join("#{pdu_uid}.json"), pdu)
    end

    #
    # Write servers info
    #

    servers_path = site_path.join("servers")
    servers_path.mkpath()
    site.fetch("servers", []).each do |server_uid, server|
      write_json(servers_path.join("#{server_uid}.json"), server)
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

      #
      # Add the manufacturing_at and warranty_end at cluster level using the manufactured_at of the oldest node
      #
      cluster["manufactured_at"] = cluster['nodes'].filter{|_n_uid, n_hash| n_hash.key? 'chassis'}.map{|_n_uid, n_hash| n_hash['chassis']['manufactured_at']}.min
      cluster["warranty_end"] = cluster['nodes'].filter{|_n_uid, n_hash| n_hash.key? 'chassis'}.map{|_n_uid, n_hash| n_hash['chassis']['warranty_end']}.min

      if cluster['queues'] && !(cluster['queues'] & %w[abaca production]).empty?
        cluster['queues'] |= %w[abaca production]
        cluster['queues'].sort!
      end

      #
      # If not defined, create the cluster priority from the manufactured date + a shift for GPU machines
      #
      if cluster['priority'].nil?
        cluster['priority'] = Time.parse(cluster['manufactured_at'].to_s).strftime('%Y%m').to_i
        if cluster["nodes"].first[1].key?("gpu_devices")
          cluster['priority'] += 100
        end
      end

      #
      # Write node info
      #

      cluster_path.join("nodes").mkpath()

      cluster["nodes"].each do |node_uid, node|# _sort_by_node_uid

        next if node['status'] == "retired"

        node.delete("status")
        queues = node.fetch('supported_job_types', {}).fetch('queues', [])
        # if abaca is here, add production, if producition is here, add abaca
        queues |= %w[abaca production] unless (queues & %w[abaca production]).empty?
        node['supported_job_types']['queues'] = queues.sort unless node['supported_job_types'].nil?

        # Convert hashes to arrays
        node["storage_devices"] = node["storage_devices"].sort_by{ |_sd, v| v['id'] }.map { |a| a[1] }

        node["network_adapters"].each { |key, _hash| node["network_adapters"][key]["device"] = key; } # Add "device: ethX" within the hash
        node["network_adapters"] = node["network_adapters"].sort_by_array(["eth0", "eth1", "eth2", "eth3", "eth4", "eth5", "eth6","eth7", "ib0.8100", "ib0", "ib1", "ib2", "ib3", "ib4", "ib5", "ib6", "ib7", "ibs1", "ibs3", "ibs4", "ibp130s0", "bmc", "eno1", "eno2", "eno3", "eno4", "eno1np0", "eno2np1", "ens4f0", "ens4f1", "ens5f0", "ens5f1", "ens10f0np0", "ens10f1np1", "fpga0", "fpga1"]).values
        node["memory_devices"].each { |key, _hash| node["memory_devices"][key]["device"] = key; } # Add "device: dimm_a1" within the hash
        node["memory_devices"] = node["memory_devices"].sort_by { |d, _|
          [d.gsub(/dimm_(\d+)/, '\1').to_i,
           d.gsub(/^dimm_([A-z]+)(\d+)$/, '\1'),
           d.gsub(/^dimm_([A-z]+)(\d+)$/, '\2').to_i]
        }.to_h
        node["memory_devices"] = node["memory_devices"].values

        write_json(cluster_path.join("nodes","#{node_uid}.json"), node)
      end

      # Add nodes details to cluster description
      cluster['nodes_count'] = cluster['nodes'].length
      first_node = cluster['nodes'].values.select { |x| not x['status'] == 'retired' }.sort_by { |x| split_cluster_node(x['uid']) }.first # use first non-retired node
      cluster['nodes_description'] = gen_node_description(first_node)

      # Write cluster info w/o nodes entries
      write_json(cluster_path.join("#{cluster_uid}.json"),
                 cluster.reject {|k, _v| k == "nodes"})

    end

  end

  # Generate the json containing all accesses level.
  accesses_path.mkpath()
  generate_accesses_json(
    accesses_path.join('nodesets.json'),
    expand_nodeset_lists
  )

end
