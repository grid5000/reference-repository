require 'date'
require 'yaml'

def gen_cluster_yaml(cluster, nodes_number)
    today = Date::today.strftime("%Y-%m-%d")
    cluster_model = "Cluster Model # TODO: change this value."
    boot_type = "uefi # TODO: specify if 'uefi' (ideally) or 'bios' (legacy, if no other choice)"
    exotic = "false # TODO: specify if 'true' or 'false'"
    manufactured_at = "1970-01-01 # TODO: Put date."
    warranty_end = "1970-01-01 # TODO: Put date."
    microarchitecture = "Haswell # TODO: replace with microarch name."
    clock_speed = "8 # TODO: Replace with clock speed."
    standard_environment = "debian11-x64-std # TODO: check that architecture is OK"
    bmc_vendor_tool = "ipmitool # TODO: replace with bmc_vendor_tool (ipmitool, racadm)"
    cluster_yaml = %{---
model: #{cluster_model}
created_at: #{today}
kavlan: false
boot_type: #{boot_type}
exotic: #{exotic}
queues:
  - admin
  - testing
nodes:
  #{cluster}-[1-#{nodes_number}]:
    chassis:
      manufactured_at: #{manufactured_at}
      warranty_end: #{warranty_end}
    supported_job_types:
      deploy: true
      besteffort: true
      max_walltime: 0
    processor:
      microarchitecture: #{microarchitecture}
      clock_speed: #{clock_speed}
    network_adapters:
      bmc:
        enabled: true
        mountable: false
        mounted: false
      eth0:
        enabled: true
        mountable: true
        mounted: true
    storage_devices:
      disk0: # This field will have to be renamed later.
        id: disk0
        interface: SAS
        by_path: "/dev/disk/by-path/dummy" # this path will have to change later.
    software:
      standard-environment: #{standard_environment}
    management_tools:
      bmc_vendor_tool: #{bmc_vendor_tool}
    nodeset: #{cluster}}
    puts(cluster_yaml)
    return cluster_yaml
end

def gen_nodes_template(cluster, nodes_number, site_ipv4_index, nodes_index, mac_bmc_list, mac_eth0_list)
    nodes_template = %{<%
  cluster_name = "#{cluster}" # Replace with cluster name
  nodes_number = #{nodes_number} # Size of the cluster (number of nodes)
  site_ipv4_index = #{site_ipv4_index} # Cluster index in the IPv4 address
  nodes_index = #{nodes_index} # Shift the last IP digit, by default 0
  # MAC addresses declaration
  #  TODO: Change MAC addresses.
  mac_eth0_list = %w(
    #{mac_eth0_list.join("\n    ")}
  )

  # TODO: Change MAC addresses.
  mac_bmc_list = %w(
    #{mac_bmc_list.join("\n    ")}
  )
%>
---
nodes:
<% (1..nodes_number).each { |i| %>
 <%= cluster_name %>-<%= i %>:
    architecture:
      nb_procs: 1 
      nb_cores: 72 
      nb_threads: 72
      platform_type: x86_64 
      cpu_core_numbering: contiguous 
    bios:
      release_date: 01/01/2000 # Fake date, will be replaced by g5k-checks
      vendor: Unknown # Fake vendor, will be replaced by g5k-checks
      version: 1 # Fake version, will be replaced by g5k-checks
    bmc_version: v1 # Fake version, will be replaced by g5k-checks
    chassis:
      manufacturer: Unknown # Fake manufacturer, will be replaced by g5k-checks
      name: Unknown # Fake name, will be replaced by g5k-checks
    main_memory:
      ram_size: 8 # Fake size, will be replaced by g5k-checks
    memory_devices:
      dimm:
        size: 8 # Fake size, will be replaced by g5k-checks
        technology: dram # Common memory technology, will be replaced by g5k-checks
    processor:
      model: Unknown # Fake model name, will be replaced by g5k-checks
      other_description: description # Fake description, will be replaced by g5k-checks
      vendor: vendor # Fake vendor, will be replaced by g5k-checks
      version: vendor # Fake version, will be replaced by g5k-checks
      cache_l1d: 8 # Fake cache, will be replaced by g5k-checks
      cache_l1i: 8 # Fake cache, will be replaced by g5k-checks
      cache_l2: 8 # Fake cache, will be replaced by g5k-checks
      cache_l3: 8 # Fake cache, will be replaced by g5k-checks
      instruction_set: x86-64 # Common instruction set, will be replaced by g5k-checks
      microcode: "0xd000001" # Fake microcode, will be replaced by g5k-checks
      ht_capable: true # Default ht capable value, will be replaced by g5k-checks 
    main_memory:
      ram_size: 8 # Fake ram size, will be replaced by g5k-checks
    memory_devices:
      dimm_proc 1 dimm 1: # Fake dimm name, will be replaced by g5k-checks
        size: 8 # Fake dimm size, will be replaced by g5k-checks
        technology: dram # Default dimm technology, will be replaced by g5k-checks
    operating_system:
      cstate_driver: unknown # Fake driver, will be replaced by g5k-checks
      cstate_governor: unknown # Fake governor, will be replaced by g5k-checks
      ht_enabled: true # common value for hyper threading, will be replaced by g5k-checks
      pstate_driver: unknwon # Fake driver, will be replaced by g5k-checks
      pstate_governor: unknown # Fake driver, will be replaced by g5k-checks
      turboboost_enabled: true # Default value for turboboost, will be replaced by g5k-checks 
    network_adapters:
      bmc:
        interface: Ethernet
        management: true
        mac: <%= mac_bmc_list[i - 1] %>
        ip: 172.17.<%= site_ipv4_index %>.<%= i + nodes_index %>
      eth0:
        interface: Ethernet
        management: false
        driver: mlx_core
        name: enp1s0f0np0
        rate: 10000000000
        mac: <%= mac_eth0_list[i - 1] %>
        ip: 172.16.<%= site_ipv4_index %>.<%= i + nodes_index %>
    storage_devices:
      disk0:
        storage: SSD # Common value, will be replaced by g5k-checks
        model: unknown # fake value,  
        size: 8 # Fake value, will be replaced by g5k-checks
<% } %>}
    puts(nodes_template)
    return nodes_template
end

def add_new_cluster(options)
    puts "Add new cluster"
    puts "Site: #{options[:site]}"
    puts "Cluster: #{options[:cluster]}"
    nodes_number = options[:nodes_number].to_i
    puts "Nodes number: #{options[:nodes_number]}"

    ipv4_yaml = YAML::load_file('input/grid5000/ipv4.yaml')
    base_ipv4 = ipv4_yaml['ipv4']['base'].split('.').map{|l| l.to_i}
    sites_offsets = ipv4_yaml['ipv4']['sites_offsets'].split("\n").map { |l| l = l.split(/\s+/) ; { l[0] => [l[1].to_i, l[2].to_i, l[3].to_i, l[4].to_i ]} }[0]
    iface_offsets = {}
    ipv4_yaml['ipv4']['iface_offsets'].split("\n").each do |offset|
        site, cluster, interface, digit1, digit2, digit3, digit4 = offset.split(/\s+/)
        if not iface_offsets.include?(site)
            iface_offsets[site] = {}
        end
        if not iface_offsets[site].include?(cluster)
            iface_offsets[site][cluster] = {}
        end
        if not iface_offsets[site][cluster].include?(interface)
            iface_offsets[site][cluster][interface] = {}
        end
        iface_offsets[site][cluster][interface] = [digit1.to_i, digit2.to_i, digit3.to_i, digit4.to_i]
    end
    nodes_index = base_ipv4[3] + options[:cluster_ipv4_digit4].to_i - sites_offsets[options[:site]][3] - 1
    site_ipv4_index = base_ipv4[2] + options[:cluster_ipv4_digit3].to_i

    digit3_ipv4 = base_ipv4[2] + site_ipv4_index - sites_offsets[options[:site]][2]
    puts "#{options[:site]} #{options[:cluster]} eth0 0 0 #{digit3_ipv4} #{nodes_index}"
    iface_offsets[options[:site]][options[:cluster]] = {}
    iface_offsets[options[:site]][options[:cluster]]["eth0"] = [0, 0, digit3_ipv4, nodes_index]
    iface_offsets_str = ""
    iface_offsets.each do |site, value_site|
      value_site.each do |cluster, value_cluster|
        value_cluster.each do |interface, value_int|
          iface_offsets_str += "#{site} #{cluster} #{interface} #{value_int[0]} #{value_int[1]} #{value_int[2]} #{value_int[3]}\n"
        end
      end
    end
    puts "Iface offsets : #{iface_offsets_str}"
    ipv4_yaml['ipv4']['iface_offsets'] = iface_offsets_str
    # ipv4_yaml['ipv4']['iface_offsets'] = ipv4_yaml['ipv4']['iface_offsets'] + "\n#{options[:site]} #{options[:cluster]} eth0 0 0 #{digit3_ipv4} #{nodes_index - 1}"
    puts("#{Psych::dump(ipv4_yaml, indentation: 4)}")
    File.open('input/grid5000/ipv4.yaml','w') do |h|
        h.write "#{Psych::dump(ipv4_yaml, indentation: 4)}"
    end

    puts "Nodes index: #{nodes_index}"
    mac_eth0_list = ["aa:bb:cc:dd:ee:01"]*nodes_number
    mac_bmc_list = ["bb:cc:dd:ee:ff:01"]*nodes_number
    path = "input/grid5000/sites/#{options[:site]}/clusters/#{options[:cluster]}"
    nodes_template = gen_nodes_template(options[:cluster], options[:nodes_number], site_ipv4_index, nodes_index, mac_bmc_list, mac_eth0_list)
    cluster_yaml = gen_cluster_yaml(options[:cluster], options[:nodes_number])


    if not Dir::exist?(path)
        puts "Create #{path}"
        FileUtils::mkdir_p(path)
        
        output_path = "#{path}/nodes.yaml.erb"
        puts "Create #{output_path}"
        output_file = File.new(output_path, 'w')
        output_file.write(nodes_template)

        path_nodes = "#{path}/nodes"
        puts "Create #{path_nodes}"
        FileUtils::mkdir_p(path_nodes)

        path_cluster = "#{path}/#{options[:cluster]}.yaml"
        puts "Create #{path_cluster}"
        output_cluster = File.new(path_cluster, 'w')
        output_cluster.write(cluster_yaml)
    else
        puts "Error, #{options[:cluster]} already exists..."
        exit(1)
    end
end