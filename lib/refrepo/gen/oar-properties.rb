# frozen_string_literal: true

require 'hashdiff'
require 'refrepo/data_loader'
require 'net/ssh'
require 'refrepo/gpu_ref'

# TODO: for gpu_model (and others?) use NULL instead of empty string

class MissingProperty < StandardError; end

MiB = 1024**2

############################################
# Functions related to the "TABLE" operation
############################################

module OarProperties
  # OAR API data cache
  @@oar_data = {}

  def table_separator(cols)
    "+-#{cols.map { |_k, v| '-' * v }.join('-+-')}-+"
  end

  def display_resources_table(generated_hierarchy)
    cols = { cluster: 11, host: 20, cpu: 5, core: 5, cpuset: 6, cpumodel: 25, gpu: 4, gpudevice: 10, gpumodel: 30 }
    puts table_separator(cols)
    puts "| #{cols.map { |k, v| k.to_s.ljust(v) }.join(' | ')} |"

    host_prev = ''
    generated_hierarchy[:nodes].map { |node| node[:oar_rows] }.flatten.each do |row|
      if row[:host] != host_prev
        puts table_separator(cols)
        host_prev = row[:host]
      end
      puts "| #{cols.map { |k, v| row[k].to_s.ljust(v) }.join(' | ')} |"
    end
    puts table_separator(cols)
  end

  ############################################
  # Functions related to the "PRINT" operation
  ############################################

  # Generates an ASCII separator
  def generate_separators
    command = "echo '================================================================================'"
    "#{command}\n"
  end

  def generate_create_disk_cmd(host, disk)
    disk_exist = "disk_exist '#{host}' '#{disk}'"
    command = "echo; echo 'Adding disk #{disk} on host #{host}:'\n"
    command += "#{disk_exist} && echo '=> disk already exists'\n"
    command += "#{disk_exist} || oarnodesetting -a -h '' -p host='#{host}' -p type='disk' -p disk='#{disk}'"
    "#{command}\n\n"
  end

  def generate_set_node_properties_cmd(host, default_properties)
    if !default_properties.nil?
      return '' if default_properties.empty?

      command  = "echo; echo 'Setting properties for #{host}:'; echo\n"
      command += "oarnodesetting --sql \"host='#{host}' and type='default'\" -p "
      command += properties_internal(default_properties)
      "#{command}\n\n"
    else
      "echo ; echo 'Not setting properties for #{host}: node is not available in ref-api'; echo\n\n"
    end
  end

  def generate_set_disk_properties_cmd(host, disk, disk_properties)
    return '' if disk_properties.empty?

    command = "echo; echo 'Setting properties for disk #{disk} on host #{host}:'; echo\n"
    command += "oarnodesetting --sql \"host='#{host}' and type='disk' and disk='#{disk}'\" -p "
    command += disk_properties_internal(disk_properties)
    "#{command}\n\n"
  end

  def generate_create_oar_property_cmd(properties_keys)
    command = ''
    ignore_keys_list = ignore_default_keys
    properties_keys.each do |key, key_type|
      next if ignore_keys_list.include?(key)
      # keys such as deploy or besteffort are default OAR keys that should not be created
      next if oar_system_keys.include?(key)

      if key_type == Integer
        command += "property_exist '#{key}' || oarproperty -a #{key}\n"
      elsif key_type == String
        command += "property_exist '#{key}' || oarproperty -a #{key} --varchar\n"
      else
        raise "Error: the type of the '#{key}' property is unknown (Integer/String). Cannot generate the corresponding 'oarproperty' command. You must create this property manually ('oarproperty -a #{key} [--varchar]')"
      end
    end
    command
  end

  # Generates helper functions:
  #   - property_exist : check if a property exists
  #   - node_exist : check if a node exists
  #   - disk_exist : check if a disk exists
  #
  # and variables which help to add nex resources:
  #   - NEXT_AVAILABLE_CPU_ID : the next identifier that can safely be used for a new cpi
  #   - NEXT_AVAILABLE_CORE_ID : the next identifier that can safely be used for a new core
  def generate_oar_commands_header
    %{
#! /usr/bin/env bash

set -eu
set -x
set -o pipefail

echo '================================================================================'

property_exist () {
  [[ $(oarproperty -l | grep -e "^$1$") ]]
}

node_exist () {
  [[ $(oarnodes --sql "host='$1' and type='default'") ]]
}

disk_exist () {
  [[ $(oarnodes --sql "host='$1' and type='disk' and disk='$2'") ]]
}


# if [ $(oarnodes -Y | grep " cpu:" | awk '{print $2}' | sort -nr | wc -c) == "0" ]; then
#   NEXT_AVAILABLE_CPU_ID=0
# else
#   MAX_CPU_ID=$(oarnodes -Y | grep " cpu:" | awk '{print $2}' | sort -nr | head -n1)
#   let "NEXT_AVAILABLE_CPU_ID=MAX_CPU_ID+1"
# fi
#
# if [ $(oarnodes -Y | grep " core:" | awk '{print $2}' | sort -nr | wc -c) == "0" ]; then
#   NEXT_AVAILABLE_CORE_ID=0
# else
#   MAX_CORE_ID=$(oarnodes -Y | grep " core:" | awk '{print $2}' | sort -nr | head -n1)
#   let "NEXT_AVAILABLE_CORE_ID=MAX_CORE_ID+1"
# fi
}
  end

  # Ensures that all required OAR properties exists.
  # OAR properties can be divided in two sets:
  #   - properties that were previously created by 'oar_resources_add'
  #   - remaining properties that can be generated from API
  def generate_oar_property_creation(site_name, data_hierarchy)
    #############################################
    # Create properties that were previously created
    # by 'oar_resources_add'
    ##############################################
    commands = %(
#############################################
# Create OAR properties that were created by 'oar_resources_add'
#############################################
property_exist 'host' || oarproperty -a host --varchar
property_exist 'cpu' || oarproperty -a cpu
property_exist 'core' || oarproperty -a core
property_exist 'gpudevice' || oarproperty -a gpudevice
property_exist 'gpu' || oarproperty -a gpu
property_exist 'disk' || oarproperty -a disk --varchar
property_exist 'diskpath' || oarproperty -a diskpath --varchar

)

    #############################################
    # Create remaining properties (from API)
    #############################################
    commands += %(
#############################################
# Create OAR properties if they don't exist
#############################################

)

    # Fetch oar properties from ref repo
    # global_hash = load_data_hierarchy
    global_hash = data_hierarchy
    site_properties = get_oar_properties_from_the_ref_repo(global_hash, {
                                                             sites: [site_name]
                                                           })[site_name]
    property_keys = get_property_keys(site_properties)

    # Generate OAR commands for creating properties
    commands += generate_create_oar_property_cmd(property_keys)

    commands
  end

  # Exports a description of OAR resources as a bunch of "self contained" OAR
  # commands. Basically it does the following:
  #   (0) * It adds an header containing helper functions and detects the next
  #         CPU and CORE IDs that could be used by new OAR resources
  #         (cf "generate_oar_commands_header()")
  #   (0) * It creates OAR properties if they don't already exist (cf "generate_oar_property_creation()")
  #   (1) * It iterates over nodes contained in the 'generated_hierarchy' hash-table
  #   (2)    > * It iterates over the oar resources of the node
  #   (3)         > * If the resource already exists, the CPU and CORE associated to the resource is detected
  #   (4)           * The resource is exported as an OAR command
  #   (5)      * If applicable, create/update the storage devices associated to the node
  def export_rows_as_oar_command(generated_hierarchy, site_name, site_properties, data_hierarchy)
    result = ''

    # Generate helper functions and detect the next available CPU and CORE IDs for
    # non exisiting resources
    result += generate_oar_commands_header

    # Ensure that OAR properties exist before creating/updating OAR resources
    result += generate_oar_property_creation(site_name, data_hierarchy)

    # Iterate over nodes of the generated resource hierarchy
    generated_hierarchy[:nodes].each do |node|
      result += %(

###################################
# #{node[:fqdn]}
###################################
)

      # Iterate over the resources of the OAR node
      node[:oar_rows].each do |oar_ressource_row|
        # host = oar_ressource_row[:host].to_s
        host = oar_ressource_row[:fqdn].to_s
        cpu = oar_ressource_row[:cpu].to_s
        core = oar_ressource_row[:core].to_s
        cpuset = oar_ressource_row[:cpuset].to_s
        gpu = oar_ressource_row[:gpu].to_s
        gpudevice = oar_ressource_row[:gpudevice].to_s
        gpumodel = oar_ressource_row[:gpumodel].to_s
        gpudevicepath = oar_ressource_row[:gpudevicepath].to_s
        resource_id = oar_ressource_row[:resource_id]

        if (resource_id == -1) || resource_id.nil?
          # Add the resource to the OAR DB
          if gpu == ''
            result += "oarnodesetting -a -h '#{host}' -s Absent -p host='#{host}' -p cpu=#{cpu} -p core=#{core} -p cpuset=#{cpuset}\n"
          else
            result += "oarnodesetting -a -h '#{host}' -s Absent -p host='#{host}' -p cpu=#{cpu} -p core=#{core} -p cpuset=#{cpuset} -p gpu=#{gpu} -p gpu_model='#{gpumodel}' -p gpudevice=#{gpudevice} # This GPU is mapped on #{gpudevicepath}\n"
          end
        elsif gpu == ''
          # Update the resource
          result += "oarnodesetting --sql \"host='#{host}' AND resource_id='#{resource_id}' AND type='default'\" -p cpu=#{cpu} -p core=#{core} -p cpuset=#{cpuset}\n"
        else
          result += "oarnodesetting --sql \"host='#{host}' AND resource_id='#{resource_id}' AND type='default'\" -p cpu=#{cpu} -p core=#{core} -p cpuset=#{cpuset} -p gpu=#{gpu} -p gpu_model='#{gpumodel}' -p gpudevice=#{gpudevice} # This GPU is mapped on #{gpudevicepath}\n"
        end
      end

      # Set the OAR properties of the OAR node
      result += generate_set_node_properties_cmd(node[:fqdn], node[:default_description])

      # Iterate over storage devices
      node[:description]['storage_devices'].select do |v|
        v.key?('reservation') and v['reservation']
      end.each do |storage_device|
        # As <storage_device> is an Array, where the first element is the device id (i.e. disk0, disk1, ...),
        # and the second element is a dictionnary containing information about the storage device,
        # thus two variables are created:
        #    - <storage_device_name> : variable that contains the device id (disk0, disk1, ...)
        #    - <storage_device_name_with_hostname> : variable that will be the ID of the storage. It follows this
        #       pattern : "disk1.ecotype-48"
        storage_device_name = storage_device['id']
        storage_device_name_with_hostname = "#{storage_device_name}.#{node[:name]}"

        # Retried the site propertie that corresponds to this storage device
        storage_device_oar_properties_tuple = site_properties['disk'].select do |keys|
          keys.include?(storage_device_name_with_hostname)
        end.first

        if storage_device_oar_properties_tuple.nil? || (storage_device_oar_properties_tuple.size < 2)
          raise "Error: could not find a site properties for disk #{storage_device_name_with_hostname}"
        end

        storage_device_oar_properties = storage_device_oar_properties_tuple[1]

        result += generate_separators

        # Ensure that the storage device exists
        result += generate_create_disk_cmd(node[:fqdn], storage_device_name_with_hostname)

        # Set the OAR properties associated to this storage device
        result += generate_set_disk_properties_cmd(node[:fqdn], storage_device_name_with_hostname,
                                                   storage_device_oar_properties)
      end

      result += generate_separators
    end

    result
  end

  ############################################
  # Functions related to the "DIFF" operation
  ############################################

  def get_ids(host)
    node_uid, site_uid, grid_uid, _tdl = host.split('.')
    cluster_uid, node_num = node_uid.split('-')
    { 'node_uid' => node_uid, 'site_uid' => site_uid, 'grid_uid' => grid_uid, 'cluster_uid' => cluster_uid,
      'node_num' => node_num }
  end

  # Get all node properties of a given site from the reference repo hash
  # See also: https://www.grid5000.fr/w/Reference_Repository
  def get_ref_default_properties(_site_uid, site)
    properties = {}
    site.fetch('clusters', {}).each do |cluster_uid, cluster|
      cluster['nodes'].each do |node_uid, node|
        properties[node_uid] = get_ref_node_properties_internal(cluster_uid, cluster, node_uid, node)
      rescue MissingProperty => e
        puts "Error (missing property) while processing node #{node_uid}: #{e}"
      rescue StandardError => e
        puts "FATAL ERROR while processing node #{node_uid}: #{e}"
        puts 'Description of the node is:'
        pp node
        raise
      end
    end
    properties
  end

  def get_ref_disk_properties(site_uid, site)
    properties = {}
    site.fetch('clusters', {}).each do |cluster_uid, cluster|
      cluster['nodes'].each do |node_uid, node|
        properties.merge!(get_ref_disk_properties_internal(site_uid, cluster_uid, cluster, node_uid, node))
      rescue MissingProperty => e
        puts "Error while processing node #{node_uid}: #{e}"
      end
    end
    properties
  end

  # Generates the properties of a single node
  def get_ref_node_properties_internal(cluster_uid, cluster, node_uid, node)
    h = {}

    main_network_adapter = node['network_adapters'].find do |na|
      /^eth[0-9]*$/.match(na['device']) && na['enabled'] && na['mounted'] && !na['management']
    end

    unless main_network_adapter
      raise MissingProperty,
            "Node #{node_uid} does not have a main network_adapter (ie. an ethernet interface with enabled=true && mounted==true && management==false)"
    end

    h['ip'] = main_network_adapter['ip']
    raise MissingProperty, "Node #{node_uid} has no IP" unless h['ip']

    h['cluster'] = cluster_uid
    h['nodemodel'] = cluster['model']
    h['nodeset'] = node['nodeset']
    h['switch'] = main_network_adapter['switch']
    h['besteffort'] = node['supported_job_types']['besteffort']
    h['deploy'] = node['supported_job_types']['deploy']
    h['virtual'] = node['supported_job_types']['virtual']
    h['cpuarch'] = node['architecture']['platform_type']
    h['cpucore'] = node['architecture']['nb_cores'] / node['architecture']['nb_procs']
    h['cpu_count'] = node['architecture']['nb_procs']
    h['core_count'] = node['architecture']['nb_cores']
    h['thread_count'] = node['architecture']['nb_threads']
    h['cputype'] = [node['processor']['model'], node['processor']['version']].join(' ')
    h['cpufreq'] = node['processor']['clock_speed'] / 1_000_000_000.0
    h['disktype'] = [node['storage_devices'].first['interface'], node['storage_devices'].first['storage']].join('/')
    h['chassis'] = [node['chassis']['manufacturer'], node['chassis']['name'], node['chassis']['serial']].join(' ')

    # ETH
    ni_mountable = node['network_adapters'].select do |na|
      /^eth[0-9]*$/.match(na['device']) && (na['enabled'] == true && (na['mounted'] == true || na['mountable'] == true))
    end
    ni_fastest = ni_mountable.max_by { |na| na['rate'] || 0 }

    h['eth_count'] = ni_mountable.length
    h['eth_kavlan_count'] = ni_mountable.select { |na| na['kavlan'] == true }.length
    h['eth_rate'] = ni_fastest['rate'] / 1_000_000_000

    if (h['eth_count']).positive? && (h['eth_rate']).zero?
      puts "#{node_uid}: Warning - no rate info for the eth interface"
    end

    # INFINIBAND
    ni_mountable = node['network_adapters'].select do |na|
      /^ib[s]?[0-9]*(\.[0-9]*)?$/.match(na['device']) && (na['interface'] == 'InfiniBand' and na['enabled'] == true && (na['mounted'] == true || na['mountable'] == true))
    end
    ni_fastest   = ni_mountable.max_by { |na| na['rate'] || 0 }
    # https://en.wikipedia.org/wiki/InfiniBand
    ib_map = { 0 => 'NO', 10 => 'SDR', 20 => 'DDR', 40 => 'QDR', 56 => 'FDR', 100 => 'EDR', 200 => 'HDR' }

    h['ib_count'] = ni_mountable.length
    h['ib_rate']  = !ni_mountable.empty? ? ni_fastest['rate'] / 1_000_000_000 : 0
    h['ib'] = ib_map[h['ib_rate']]

    unless ib_map.key?(h['ib_rate'])
      puts "#{node_uid}: Warning - unkwnon ib kind for rate #{h['ib_rate']}, update ib_map variable"
    end
    puts "#{node_uid}: Warning - no rate info for the ib interface" if (h['ib_count']).positive? && (h['ib_rate']).zero?

    # OMNIPATH
    ni_mountable = node['network_adapters'].select do |na|
      /^ib[s]?[0-9]*(\.[0-9]*)?$/.match(na['device']) && (na['interface'] == 'Omni-Path' and na['enabled'] == true && (na['mounted'] == true || na['mountable'] == true))
    end
    ni_fastest = ni_mountable.max_by { |na| na['rate'] || 0 }

    h['opa_count'] = ni_mountable.length
    h['opa_rate']  = !ni_mountable.empty? ? ni_fastest['rate'] / 1_000_000_000 : 0

    if (h['opa_count']).positive? && (h['opa_rate']).zero?
      puts "#{node_uid}: Warning - no rate info for the opa interface"
    end

    # MYRINET
    ni_mountable = node['network_adapters'].select do |na|
      /^myri[0-9]*$/.match(na['device']) && (na['enabled'] == true && (na['mounted'] == true || na['mountable'] == true))
    end
    ni_fastest = ni_mountable.max_by { |na| na['rate'] || 0 }
    myri_map = { 0 => 'NO', 2 => 'Myrinet-2000', 10 => 'Myri-10G' }

    h['myri_count'] = ni_mountable.length
    h['myri_rate']  = !ni_mountable.empty? ? ni_fastest['rate'] / 1_000_000_000 : 0
    h['myri'] = myri_map[h['myri_rate']]

    if (h['myri_count']).positive? && (h['myri_rate']).zero?
      puts "#{node_uid}: Warning - no rate info for the myri interface"
    end

    h['memcore'] = node['main_memory']['ram_size'] / node['architecture']['nb_cores'] / MiB
    h['memcpu'] = node['main_memory']['ram_size'] / node['architecture']['nb_procs'] / MiB
    h['memnode'] = node['main_memory']['ram_size'] / MiB

    h['gpu_model'] = ''
    h['gpu_count'] = 0
    h['gpu_mem'] = 0
    h['gpu_compute_capability'] = 'N/A'
    h['gpu_compute_capability_major'] = 0

    if node.key?('gpu_devices')
      models = node['gpu_devices'].map { |_, g| g['model'] }.uniq
      raise "Node #{h['uid']} has more than one model of GPU" if models.length > 1

      device = node['gpu_devices'].first[1]
      if GPURef.is_gpu_supported?(device)
        h['gpu_model'] = device['model']
        h['gpu_count'] = node['gpu_devices'].length
        h['gpu_mem'] = device['memory'] / MiB
        unless ['AMD'].include?(device['vendor']) # not supported on AMD GPUs
          h['gpu_compute_capability'] = device['compute_capability']
          h['gpu_compute_capability_major'] = device['compute_capability'].split('.').first.to_i
        end
      end
    end

    h['exotic'] = if node.key?('exotic')
                    node['exotic']
                  else
                    false
                  end

    h['mic'] = if node['mic']
                 'YES'
               else
                 'NO'
               end

    h['wattmeter'] = if cluster.fetch('metrics', []).any? do |metric|
                          metric['name'].match(/wattmetre_power_watt|pdu_outlet_power_watt/)
                        end
                       'YES'
                     else
                       'NO'
                     end
    h['cluster_priority'] = cluster['priority'].to_i

    h['max_walltime'] = 0 # default
    if node['supported_job_types']&.key?('max_walltime')
      h['max_walltime'] =
        node['supported_job_types']['max_walltime']
    end

    h['production'] = get_production_property(node)
    h['maintenance'] = get_maintenance_property(node)

    # Disk reservation
    h['disk_reservation_count'] = node['storage_devices'].select { |v| v['reservation'] }.length

    # convert booleans to YES/NO string
    h.each do |k, v|
      case v
      when true
        h[k] = 'YES'
      when false
        h[k] = 'NO'
      when Float
        h[k] = v.to_s
      end
    end

    h
  end

  def get_production_property(node)
    if ['abaca','production'].any? {|n| node.fetch('supported_job_types',{}).fetch('queues',[]).include?(n)}
      'YES'
    else
      'NO'
    end
  end

  def get_maintenance_property(node)
    maintenance = false # default
    if node['supported_job_types']&.key?('queues')
      maintenance = node['supported_job_types']['queues'].include?('testing')
    end
    maintenance == true ? 'YES' : 'NO'
  end

  # Return a list of properties as a hash: { property1 => String, property2 => Integer, ... }
  # We detect the type of the property (Integer/String) by looking at the existing values
  def get_property_keys(properties)
    properties_keys = {}
    properties.each do |type, type_properties|
      properties_keys.merge!(get_property_keys_internal(type, type_properties))
    end
    properties_keys
  end

  def properties_internal(properties)
    properties
      .to_a
      .reject { |k, _v| ignore_default_keys.include? k }
      .map do |(k, v)|
      v = 'YES' if v == true
      v = 'NO'  if v == false
      !v.nil? ? "#{k}=#{v.inspect.gsub("'", "\\'").gsub('"', "'")}" : nil
    end.compact.join(' -p ')
  end

  def disk_properties_internal(properties)
    properties
      .to_a
      .select { |_k, v| !v.nil? and v != '' }
      .map do |(k, v)|
      v = 'YES' if v == true
      v = 'NO'  if v == false
      !v.nil? ? "#{k}=#{v.inspect.gsub("'", "\\'").gsub('"', "'")}" : nil
    end.compact.join(' -p ')
  end

  # Returns the expected properties of the reservable disks. These
  # properties are then compared with the values in OAR database, to
  # generate a diff.
  # The key is of the form [node, disk]. In the following example
  # we list the different disks (from disk1 to disk5) of node grimoire-1.
  # {["grimoire-1", "disk1.grimoire-1"]=>
  #  {"cluster"=>"grimoire",
  #  "host"=>"grimoire-1.nancy.grid5000.fr",
  #  "network_address"=>"",
  #  "available_upto"=>0,
  #  "deploy"=>"YES",
  #  "production"=>"NO",
  #  "maintenance"=>"NO",
  #  "disk"=>"disk1.grimoire-1",
  #  "diskpath"=>"/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:1:0",
  #  "cpuset"=>-1},
  #  ["grimoire-1", "disk2.grimoire-1"]=> ...
  def get_ref_disk_properties_internal(site_uid, cluster_uid, cluster, node_uid, node)
    properties = {}
    node['storage_devices'].each_with_index do |device, index|
      disk = [device['id'], node_uid].join('.')
      next unless index.positive? && device['reservation'] # index > 0 is used to exclude disk0

      key = [node_uid, disk]
      # Start by copying the properties of the resource of type default,
      # because to reserve both the resources of type disk and of type default
      # for a same host, almost all properties must have the same value.
      # In particular, max_walltime must be identic, but mind that that
      # max_walltime properties is not related to the max duration of a job
      # containing only disk resources (14days), it is not used for that.
      h = get_ref_node_properties_internal(cluster_uid, cluster, node_uid, node)
      # We set the host property because it's not done in what we got above
      h['host'] = [node_uid, site_uid, 'grid5000.fr'].join('.')
      # We do not set network_address and available_upto for disk resources
      # (FIXME: recall why)
      h['network_address'] = ''
      h['available_upto'] = 0
      # We set the disk specific property values
      h['disk'] = disk
      h['diskpath'] = device['by_path']
      h['cpuset'] = -1
      properties[key] = h
    end
    properties
  end

  def get_oar_default_properties(site_uid, options)
    oarnodes = get_oar_data(site_uid, options)
    oarnodes.select { |v| v['type'] == 'default' }.map { |v| [get_ids(v['host'])['node_uid'], v] }.to_h
  end

  def get_oar_disk_properties(site_uid, options)
    oarnodes = get_oar_data(site_uid, options)
    oarnodes.select do |v|
      v['type'] == 'disk'
    end.map { |v| [[get_ids(v['host'])['node_uid'], v['disk']], v] }.to_h
  end

  # Get all data from the OAR database
  def get_oar_data(site_uid, options)
    data_key = [site_uid, options].to_s
    # is data already in cache ?
    if @@oar_data[data_key].nil?
      # If no API URL is given, set a default URL on https://api.grid5000.fr
      options[:api][:uri] = 'https://api.grid5000.fr' unless options[:api][:uri]

      # Preparing the URL that will be used to fetch OAR resources
      if options[:api][:uri].include? 'api.grid5000.fr'
        api_uri = URI.parse("https://api.grid5000.fr/stable/sites/#{site_uid}/internal/oarapi/resources/details.json?limit=999999")
      elsif options[:api][:uri].include? 'api-ext.grid5000.fr'
        api_uri = URI.parse("https://api-ext.grid5000.fr/stable/sites/#{site_uid}/internal/oarapi/resources/details.json?limit=999999")
      else
        api_uri = URI.parse("#{options[:api][:uri]}/oarapi/resources/details.json?limit=999999")
      end

      # Download the OAR properties from the OAR API (through G5K API)
      http = Net::HTTP.new(api_uri.host, api_uri.port)
      http.use_ssl = true if api_uri.scheme == 'https'
      request = Net::HTTP::Get.new(api_uri.request_uri, { 'User-Agent' => 'reference-repository/gen/oar-properties' })

      # For outside g5k network access
      request.basic_auth(options[:api][:user], options[:api][:pwd]) if options[:api][:user] && options[:api][:pwd]

      response = http.request(request)
      raise "Failed to fetch resources properties from API: \n#{response.body}\n" unless response.code.to_i == 200

      oarnodes = JSON.parse(response.body)

      # Adapt from the format of the OAR API
      oarnodes = oarnodes['items'] if oarnodes.key?('items')
      @@oar_data[data_key] = oarnodes
    end
    # Return a deep copy of the cached value as it will be modified in place
    Marshal.load(Marshal.dump(@@oar_data[data_key]))
  end

  def get_property_keys_internal(_type, type_properties)
    properties_keys = {}
    type_properties.each do |key, node_properties|
      # Differenciate between 'default' type (key = node_uid)
      # and 'disk' type (key = [node_uid, disk_id])
      node_uid, = key
      next if node_uid.nil?

      node_properties.each do |k, v|
        next if properties_keys.key?(k)
        next if v.is_a?(NilClass)
        # also skip detection if 'v == false' because it seems that if a varchar property
        # only as 'NO' values, it might be interpreted as a boolean
        # (see the ib property at nantes: ib: NO in the YAML instead of ib: 'NO')
        next if v == false

        properties_keys[k] = v.class
      end
    end
    properties_keys
  end

  def diff_properties(type, properties_oar, properties_ref)
    properties_oar ||= {}
    properties_ref ||= {}

    case type
    when 'default'
      ignore_keys = ignore_keys()
    when 'disk'
      check_keys = %w[cluster host network_address available_upto deploy production maintenance disk diskpath cpuset]
      ignore_keys = ignore_keys() - check_keys # Some key must be ignored for default but not for disks, ex: available_upto
    end
    ignore_keys.each { |key| properties_oar.delete(key) }
    ignore_keys.each { |key| properties_ref.delete(key) }

    Hashdiff.diff(properties_oar, properties_ref)
  end

  # These keys will not be created neither compared with the -d option
  # ignore_default_keys is only applied to resources of type 'default'
  def ignore_default_keys
    # default OAR at resource creation:
    #  available_upto: '2147483647'
    #  besteffort: 'YES'
    #  core: ~
    #  cpu: ~
    #  cpuset: 0
    #  deploy: 'NO'
    #  desktop_computing: 'NO'
    #  drain: 'NO'
    #  expiry_date: 0
    #  finaud_decision: 'YES'
    #  host: ~
    #  last_available_upto: 0
    #  last_job_date: 0
    #  network_address: server
    #  next_finaud_decision: 'NO'
    #  next_state: UnChanged
    #  resource_id: 9
    #  scheduler_priority: 0
    #  state: Suspected
    #  state_num: 3
    #  suspended_jobs: 'NO'
    #  type: default
    [
      'slash_16',
      'slash_17',
      'slash_18',
      'slash_19',
      'slash_20',
      'slash_21',
      'slash_22',
      'available_upto',
      'chunks',
      'comment', # TODO
      'core', # This property was created by 'oar_resources_add'
      'cpu', # This property was created by 'oar_resources_add'
      'host', # This property was created by 'oar_resources_add'
      'gpudevice', # New property taken into account by the new generator
      'gpu', # New property taken into account by the new generator
      'cpuset',
      'desktop_computing',
      'drain',
      'expiry_date',
      'finaud_decision',
      'grub',
      'jobs', # This property exists when a job is running
      'last_available_upto',
      'last_job_date',
      'network_address', # TODO
      'next_finaud_decision',
      'next_state',
      'rconsole', # TODO
      'resource_id',
      'scheduler_priority',
      'state',
      'state_num',
      'subnet_address',
      'subnet_prefix',
      'suspended_jobs',
      'thread',
      'type', # TODO
      'vlan',
      'pdu',
      'id', # id from API (= resource_id from oarnodes)
      'api_timestamp', # from API
      'links' # from API
    ]
  end

  # Properties of resources of type 'disk' to ignore (for example, when
  # comparing resources of type 'default' with the -d option)
  def ignore_disk_keys
    %w[
      disk
      diskpath
    ]
  end

  def ignore_keys
    ignore_default_keys + ignore_disk_keys
  end

  # Properties such as deploy and besteffort, that should not be created
  def oar_system_keys
    %w[
      deploy
      besteffort
    ]
  end

  def get_oar_resources_from_oar(options)
    properties = {}
    options.fetch(:sites).each do |site_uid|
      properties[site_uid] = {
        'resources' => get_oar_data(site_uid, options)
      }
    end
    properties
  end

  # sudo exec
  def run_commands_via_ssh(cmds, options, verbose = true)
    # The following is equivalent to : "cat cmds | bash"
    res = ''
    c = Net::SSH.start(options[:ssh][:host], options[:ssh][:user])
    c.open_channel do |channel|
      channel.exec('sudo bash') do |_ch, _success|
        # stdout
        channel.on_data do |_ch2, data|
          puts data if verbose
          res += data
        end
        # stderr
        channel.on_extended_data do |_ch2, _type, data|
          puts data if verbose
          res += data
        end

        channel.send_data cmds
        channel.eof!
      end
    end
    c.loop
    c.close
    res
  end

  # Get the properties of each node
  def get_oar_properties_from_the_ref_repo(global_hash, options)
    properties = {}
    options.fetch(:sites).each do |site_uid|
      properties[site_uid] = {
        'default' => get_ref_default_properties(site_uid, global_hash.fetch('sites').fetch(site_uid)),
        'disk' => get_ref_disk_properties(site_uid, global_hash.fetch('sites').fetch(site_uid))
      }
    end
    properties
  end

  def get_oar_properties_from_oar(options)
    properties = {}
    options.fetch(:sites).each do |site_uid|
      properties[site_uid] = {
        'default' => get_oar_default_properties(site_uid, options),
        'disk' => get_oar_disk_properties(site_uid, options)
      }
    end
    properties
  end

  def do_diff(options, generated_hierarchy, refrepo_properties)
    raise if options[:update] || options[:print] # no longer supported, was never really supported

    ret = 0

    diagnostic_msgs = []

    properties = {
      'ref' => refrepo_properties,
      'oar' => get_oar_properties_from_oar(options)
    }

    # Get the list of property keys from the reference-repo (['ref'])
    properties_keys = {
      'ref' => {},
      'oar' => {},
      'diff' => {}
    }

    options[:sites].each do |site_uid|
      properties_keys['ref'][site_uid] = get_property_keys(properties['ref'][site_uid])
    end
    ignore_default_keys = ignore_default_keys()

    # Build the list of nodes that are listed in properties['oar'],
    # but does not exist in properties['ref']
    missings_alive = []
    missings_dead = []
    properties['oar'].each do |site_uid, site_properties|
      site_properties['default'].each_filtered_node_uid(options[:clusters],
                                                        options[:nodes]) do |node_uid, node_properties_oar|
        unless properties['ref'][site_uid]['default'][node_uid]
          if node_properties_oar['state'] != 'Dead'
            missings_alive << node_uid
          else
            missings_dead << node_uid
          end
        end
      end
    end

    unless missings_alive.empty?
      diagnostic_msgs.push("*** Error: The following nodes exist in the OAR server but are missing in the reference-repo: #{missings_alive.join(', ')}.\n")
      ret = false
    end

    prev_diff = {}
    properties['diff'] = {}

    header = false
    properties['ref'].each do |site_uid, site_properties|
      properties['diff'][site_uid] = {}
      site_properties.each do |type, type_properties|
        properties['diff'][site_uid][type] = {}
        type_properties.each_filtered_node_uid(options[:clusters], options[:nodes]) do |key, properties_ref|
          # As an example, key can be equal to 'grimoire-1' for default resources or
          # ['grimoire-1', 1] for disk resources (disk n°1 of grimoire-1)

          properties_oar = properties['oar'][site_uid][type][key]

          diff = diff_properties(type, properties_oar, properties_ref) # NOTE: this deletes some properties from the input parameters
          diff_keys = diff.map { |hashdiff_array| hashdiff_array[1] }
          properties['diff'][site_uid][type][key] = properties_ref.select { |k, _v| diff_keys.include?(k) }

          info = if properties['oar'][site_uid][type][key].nil?
                   (type == 'default' ? ' new node !' : ' new disk !')
                 else
                   ''
                 end

          if header == false
            # output header only once
            diagnostic_msgs.push("Output format: [ '-', 'key', 'value'] for missing, [ '+', 'key', 'value'] for added, ['~', 'key', 'old value', 'new value'] for changed")
            header = true
          end
          if diff.empty?
            diagnostic_msgs.push("  #{key}: OK#{info}")
          elsif diff == prev_diff
            diagnostic_msgs.push("  #{key}:#{info} same modifications as above")
          else
            diagnostic_msgs.push("  #{key}:#{info}")
            diff.each { |d| diagnostic_msgs.push("    #{d}") }
          end
          prev_diff = diff
          ret = false unless diff.empty?
        end
      end

      # Get the list of property keys from the OAR scheduler (['oar'])
      properties_keys['oar'][site_uid] = get_property_keys(properties['oar'][site_uid])

      # Build the list of properties that must be created in the OAR server
      properties_keys['diff'][site_uid] = {}
      properties_keys['ref'][site_uid].each do |k, v_ref|
        v_oar = properties_keys['oar'][site_uid][k]
        properties_keys['diff'][site_uid][k] = v_ref unless v_oar
        next unless v_oar && v_oar != v_ref && v_ref != NilClass && v_oar != NilClass

        # Detect inconsistency between the type (String/Integer) of properties generated by this script and the existing values on the server.
        diagnostic_msgs.push("Error: the OAR property '#{k}' is a '#{v_oar}' on the #{site_uid} server and this script uses '#{v_ref}' for this property.")
        ret = false
      end

      unless properties_keys['diff'][site_uid].keys.to_a.delete_if do |e|
               ignore_keys.include?(e)
             end.empty?
        diagnostic_msgs.push("Properties that need to be created on the #{site_uid} server: #{properties_keys['diff'][site_uid].keys.to_a.delete_if do |e|
                                                                                                ignore_keys.include?(e)
                                                                                              end.join(', ')}")
      end

      # Detect unknown properties
      unknown_properties = properties_keys['oar'][site_uid].keys.to_set - properties_keys['ref'][site_uid].keys.to_set
      ignore_default_keys.each do |key|
        unknown_properties.delete(key)
      end

      unless unknown_properties.empty?
        diagnostic_msgs.push("Properties existing on the #{site_uid} server but not managed/known by the generator: #{unknown_properties.to_a.join(', ')}.")
        diagnostic_msgs.push("Hint: you can delete properties with 'oarproperty -d <property>' or add them to the ignore list in lib/lib-oar-properties.rb.")
        ret = false
      end

      diagnostic_msgs.map { |msg| puts(msg) } unless options[:print]

      # Check that CPUSETs on the OAR server are consistent with what would have been generated
      oar_resources = get_oar_resources_from_oar(options)

      error_msgs = ''

      options[:clusters].each do |cluster|
        generated_rows_for_this_cluster = generated_hierarchy[:nodes]
                                          .map { |node| node[:oar_rows] }
                                          .flatten
                                          .select { |r| r[:cluster] == cluster }

        site_resources = oar_resources[site_uid]['resources']
        cluster_resources = site_resources.select { |x| x['cluster'] == cluster }
        default_cluster_resources = cluster_resources.select { |r| r['type'] == 'default' }

        next if generated_rows_for_this_cluster.empty?

        # Check that OAR resources are associated with the right cpu, core and cpuset
        generated_rows_for_this_cluster.each do |row|
          corresponding_resource = default_cluster_resources.select { |r| r['id'] == row[:resource_id] }
          if !corresponding_resource.empty?
            resc = corresponding_resource[0]

            { cpu: 'cpu', core: 'core', cpuset: 'cpuset', gpu: 'gpu',
              gpudevice: 'gpudevice' }.each do |key, value|
              unless (row[key].to_s != corresponding_resource[0][value].to_s) && !((key == :gpu) && row[key].nil? && (corresponding_resource[0][value]).zero?)
                next
              end

              expected_value = row[key]
              expected_value = 'null' if (expected_value == '') || expected_value.nil?
              diagnostic_msg = <<~TXT
                # Error: Resource #{resc['id']} (host=#{resc['network_address']} cpu=#{resc['cpu']} core=#{resc['core']} cpuset=#{resc['cpuset']} gpu=#{resc['gpu']} gpudevice=#{resc['gpudevice']}) has a mismatch for ressource #{value.upcase}: OAR API gives #{resc[value]}, generator wants #{expected_value}.
              TXT
              error_msgs += diagnostic_msg.to_s
            end
          elsif row[:resource_id] != -1
            # If resource_id is not equal to -1, then the generator is working on a resource that should exist,
            # however it cannot be found : the generator reports an error to the operator
            puts "Error: could not find ressource with ID=#{row[:resource_id]}"
          end
        end
      end

      if !(options[:print]) && !error_msgs.empty?
        puts error_msgs
        ret = false
      end
    end

    ret
  end

  def sanity_check(cluster_resources, site_resources)
    # Detect cluster resources
    cluster_cpus = cluster_resources.map { |r| r['cpu'] }.uniq
    cluster_gpus = cluster_resources.map { |r| r['gpu'] }.reject(&:nil?).uniq
    cluster_cores = cluster_resources.map { |r| r['core'] }.uniq

    # Check CPUs
    cluster_cpus.each do |cluster_cpu|
      hosts_with_same_cpu = site_resources.select { |r| r['cpu'] == cluster_cpu }.map { |r| r['host'] }.uniq

      next unless hosts_with_same_cpu.length > 1

      puts('################################')
      puts("# Error: CPU #{cluster_cpu} is associated to more than one host: #{hosts_with_same_cpu}.")
      puts("# You can review this situation via the following command:\n")
      puts('################################')
      puts("oarnodes -Y --sql \"cpu=#{cluster_cpu}\"")
      puts('')

      return false
    end

    # Checks GPUs
    cluster_gpus.each do |cluster_gpu|
      hosts_with_same_gpu = site_resources.select { |r| r['gpu'] == cluster_gpu }.map { |r| r['host'] }.uniq

      next unless hosts_with_same_gpu.length > 1

      puts('################################')
      puts("# Error: GPU #{cluster_gpu} is associated to more than one host: #{hosts_with_same_gpu}.")
      puts("# You can review this situation via the following command:\n")
      puts('################################')
      puts("oarnodes -Y --sql \"gpu=#{cluster_gpu}\"")
      puts('')

      return false
    end

    # Check Cores
    cluster_cores.each do |cluster_core|
      resources_id_with_same_core = site_resources.select { |r| r['core'] == cluster_core }.map { |r| r['id'] }

      next unless resources_id_with_same_core.length > 1

      oar_sql_clause = resources_id_with_same_core.map { |rid| "resource_id='#{rid}'" }.join(' OR ')

      puts('################################')
      puts("# Error: resources with ids #{resources_id_with_same_core} have the same value for core (core is equal to #{cluster_core})\n")
      puts("# You can review this situation via the following command:\n")
      puts('################################')
      puts("oarnodes -Y --sql \"#{oar_sql_clause}\"")
      puts('')

      return false
    end

    true
  end

  def extract_clusters_description(clusters, site_name, options, data_hierarchy, site_properties)
    # This function works as follow:
    # (1) Initialization
    #    (a) Load the local data contained in JSON data files
    #    (b) Handle the program arguments (detects which site and which clusters
    #        are targeted), and what action is requested
    #    (c) Fetch the OAR properties of the requested site
    # (2) Generate an OAR node hierarchy
    #    (a) Iterate over cluster > nodes > cpus > cores
    #    (b) Detect existing resource_ids and {CPU, CORE, CPUSET, GPU}'s IDs
    #    (c) [if cluster with GPU] detects the existing mapping GPU <-> CPU in the cluster
    #    (d) Associate a cpuset to each core
    #    (e) [if cluster with GPU] Associate a gpuset to each core

    ############################################
    # (1) Initialization
    ############################################

    oar_resources = get_oar_resources_from_oar(options)

    generated_hierarchy = {
      nodes: []
    }

    ############################################
    # (2) Generate an OAR node hierarchy
    ############################################

    site_resources = oar_resources[site_name]['resources'].select { |r| r['type'] == 'default' }

    next_rsc_ids = {
      'cpu' => !site_resources.empty? ? site_resources.map { |r| r['cpu'] }.max : 0,
      'core' => !site_resources.empty? ? site_resources.map { |r| r['core'] }.max : 0,
      'gpu' => !site_resources.empty? ? site_resources.map { |r| r['gpu'] }.reject(&:nil?).max : 0
    }

    # Some existing cluster have GPUs, but no GPU ID has been allocated to them
    next_rsc_ids['gpu'] = 0 if next_rsc_ids['gpu'].nil?

    ############################################
    # (2-a) Iterate over clusters. (rest: servers, cpus, cores)
    ############################################

    clusters.sort.each do |cluster_name|
      cpu_idx = 0
      core_idx = 0

      unless data_hierarchy['sites'][site_name]['clusters'].include?(cluster_name)
        puts("It seems that the cluster \"#{cluster_name}\" does not exist in the API. The generator will abort.")
        raise 'Sanity check failed'
      end

      cluster_nodes = data_hierarchy['sites'][site_name]['clusters'][cluster_name]['nodes']

      node_count = cluster_nodes.length

      cluster_resources = site_resources
                          .select { |r| r['cluster'] == cluster_name }
                          .select { |r| cluster_nodes.include?(r['host'].split('.')[0]) }
                          .sort_by { |r| [r['cpu'], r['core']] }

      sanity_check_result = sanity_check(cluster_resources, site_resources)
      unless sanity_check_result
        puts("It seems that the cluster \"#{cluster_name}\" has some incoherence in its resource configuration (see above). The generator will abort.")
        raise 'Sanity check failed'
      end

      first_node = cluster_nodes.first[1]

      cpu_count = first_node['architecture']['nb_procs']
      cpu_core_count = first_node['architecture']['nb_cores'] / cpu_count
      cpu_thread_count = first_node['architecture']['nb_threads'] / cpu_count
      core_thread_count = first_node['architecture']['nb_threads'] / first_node['architecture']['nb_cores']
      gpu_count = cluster_nodes.values.map { |e| (e['gpu_devices'] || {}).length }.max

      cpu_model = "#{first_node['processor']['model']} #{first_node['processor']['version']}"
      core_numbering = first_node['architecture']['cpu_core_numbering']

      ############################################
      # (2-b) Detect existing resource_ids and {CPU, CORE, CPUSET, GPU}'s IDs
      ############################################

      # <phys_rsc_map> is a hash that centralises variables that will be used for managing IDs of CPUs, COREs, GPUs of
      # the cluster that is going to be updated. <phys_rsc_map> is useful to detect situations where the current number
      # of resources associated to a cluster does not correspond to the needs of the cluster.
      phys_rsc_map = {
        'cpu' => {
          current_ids: [],
          per_server_count: cpu_count,
          per_cluster_count: node_count * cpu_count
        },
        'core' => {
          current_ids: [],
          per_server_count: cpu_core_count,
          per_cluster_count: node_count * cpu_count * cpu_core_count
        },
        'gpu' => {
          current_ids: [],
          per_server_count: gpu_count,
          per_cluster_count: # sum
cluster_nodes.values.map do |e|
  (e['gpu_devices'] || {}).length
end.inject(0) { |a, b| a + b }
        }
      }

      # For each physical ressource, we prepare a list of IDs:
      #   a) we start with the IDs of the list of existing resources
      #   b) we add more if needed
      phys_rsc_map.each do |physical_resource, variables|
        current_ids = cluster_resources.map { |r| r[physical_resource] }.reject(&:nil?).uniq
        if current_ids.length > variables[:per_cluster_count]
          raise "#{physical_resource}: too many IDs in OAR compared to what we need to generate. This case needs to be fixed manually."
        elsif current_ids.length < variables[:per_cluster_count]
          # there are less resources currently affected to that cluster than what is needed. affect more and bump next_rsc_ids
          needed = variables[:per_cluster_count] - current_ids.length
          current_ids += [*next_rsc_ids[physical_resource] + 1..next_rsc_ids[physical_resource] + needed]
          next_rsc_ids[physical_resource] =
            (variables[:per_server_count]).positive? ? variables[:current_ids].max : next_rsc_ids[physical_resource]
        end

        variables[:current_ids] = current_ids
      end

      oar_resource_ids = cluster_resources.map { |r| r['id'] }.uniq
      if oar_resource_ids.length < phys_rsc_map['core'][:current_ids].length
        # the cluster has less resource ids than needed (because resources were added to it)
        needed = phys_rsc_map['core'][:current_ids].length - oar_resource_ids.length
        # -1 here asks to generate the resources, not change them
        oar_resource_ids += [*1..needed].map { -1 }
      end

      # Some cluster (econome) have attributed resources according to the "alpha-numerical" order of nodes
      # ([1, 11, 12, ..., 3] instead of [1, 2, 3, 4, ...]). Here we preserve to order of existing nodes of the cluster
      nodes_names = cluster_resources.map { |r| r['host'] }.map { |fqdn| { fqdn: fqdn, name: fqdn.split('.')[0] } }.uniq
      if nodes_names.length != node_count
        # some missing nodes. we regenerate the list from scratch
        nodes_names = (1..node_count).map do |i|
          { name: "#{cluster_name}-#{i}", fqdn: "#{cluster_name}-#{i}.#{site_name}.grid5000.fr" }
        end
      end

      ############################################
      # Suite of (2-a): Iterate over nodes of the cluster. (rest: cpus, cores)
      ############################################

      (1..node_count).each do |node_num|
        # node_index0 starts at 0
        node_index0 = node_num - 1

        name = nodes_names[node_index0][:name]
        fqdn = nodes_names[node_index0][:fqdn]

        node_description = cluster_nodes[name]

        node_description_default_properties = site_properties['default'][name]

        next if node_description.nil?

        generated_node_description = {
          name: name,
          fqdn: fqdn,
          cluster_name: cluster_name,
          site_name: site_name,
          description: node_description,
          oar_rows: [],
          disks: [],
          gpus: (if !node_description['gpu_devices'].nil?
                   node_description['gpu_devices'].select do |_k, v|
                     v.fetch('reservation', true)
                   end.length
                 else
                   0
                 end),
          default_description: node_description_default_properties
        }

        ############################################
        # Suite of (2-a): Iterate over CPUs of the server. (rest: cores)
        ############################################
        (0...cpu_count).each do |cpu_num|
          ############################################
          # Suite of (2-a): Iterate over CORES of the CPU
          ############################################
          (0...cpu_core_count).each do |core_num|
            # Compute cpu and core ID
            oar_resource_id = oar_resource_ids[core_idx]
            cpu_id = phys_rsc_map['cpu'][:current_ids][cpu_idx]
            core_id = phys_rsc_map['core'][:current_ids][core_idx]

            # Prepare an Hash that represents a single OAR resource. Few
            # keys are initialized with empty values.
            row = {
              cluster: cluster_name,
              host: name,
              cpu: cpu_id,
              core: core_id,
              cpuset: nil,
              gpu: nil,
              gpudevice: nil,
              gpudevicepath: nil,
              cpumodel: nil,
              gpumodel: nil,
              oar_properties: nil,
              fqdn: fqdn,
              resource_id: oar_resource_id
            }

            ############################################
            # (2-d) Associate a cpuset to each core
            # See https://www.grid5000.fr/w/TechTeam:CPU_core_numbering
            ############################################
            case core_numbering
            when 'contiguous'
              row[:cpuset] = cpu_num * cpu_core_count + core_num
            when 'contiguous-including-threads'
              row[:cpuset] = cpu_num * cpu_thread_count + core_num
            when 'contiguous-grouped-by-threads'
              row[:cpuset] = cpu_num * cpu_thread_count + core_num * core_thread_count
            when 'round-robin'
              row[:cpuset] = cpu_num + core_num * cpu_count
            else
              raise
            end

            row[:cpumodel] = cpu_model

            ############################################
            # (2-e) [if cluster with GPU] Associate a gpuset to each core
            ############################################

            if node_description.key?('gpu_devices') && !node_description['gpu_devices'].values.select do |v|
                 v.fetch('reservation', true)
               end.empty?
              # The node has reservable GPUs

              # numa_gpus is the list of gpus for the current CPU
              numa_gpus = node_description['gpu_devices'].values.select do |v|
                field = if v.key? 'cpu_affinity_override'
                          'cpu_affinity_override'
                        else
                          'cpu_affinity'
                        end
                v[field] == cpu_num and v.fetch('reservation', true)
              end
              if numa_gpus.empty?
                # This core is not associated to any GPU
                if node_description['gpu_devices'].values.select { |v| v.fetch('reservation', true) }.length == 1
                  # The node has only one reservable GPU, we affect it to all cores
                  selected_gpu = node_description['gpu_devices'].values.first
                else
                  raise "#{fqdn}: No GPU to associate to CPU #{cpu_num}, core #{row[:cpuset]}. You probably want to use cpu_affinity_override to affect a GPU to this CPU."
                end
              elsif numa_gpus.first.key? 'cores_affinity'
                # this cluster uses cores_affinity, not arbitrary allocation
                selected_gpu = numa_gpus.find do |g|
                  g['cores_affinity'].split.map(&:to_i).include?(row[:cpuset])
                end
                raise "Could not find a GPU on CPU #{cpu_num} for core #{row[:cpuset]}" if selected_gpu.nil?
              else
                # The parenthesis order is important: we want to keep the
                # integer division to generate an integer index, so we want to
                # do the multiplication first.
                gpu_idx = (core_num * numa_gpus.length) / cpu_core_count
                selected_gpu = numa_gpus[gpu_idx]
              end
              # id of the selected GPU in the node
              local_id = node_description['gpu_devices'].values.index(selected_gpu)

              # to assign the gpu number, just use the number of nodes and the number of GPUs per node
              # sanity check: we must fall into the correct range
              gpu = phys_rsc_map['gpu'][:current_ids].min + node_index0 * gpu_count + local_id
              raise "Invalid GPU number for cluster #{cluster_name}" if gpu > phys_rsc_map['gpu'][:current_ids].max

              row[:gpu] = gpu
              row[:gpudevice] = local_id
              row[:gpudevicepath] = selected_gpu['device']
              row[:gpumodel] = selected_gpu['model']
            end

            core_idx += 1

            generated_node_description[:oar_rows].push(row)
          end
          cpu_idx += 1
        end

        generated_hierarchy[:nodes].push(generated_node_description)
      end
    end
    generated_hierarchy
  end

  ############################################
  # MAIN function
  ############################################

  # This function is called from RAKE and is in charge of
  #   - printing OAR commands to
  #      > add a new cluster
  #      > update and existing cluster
  #   - execute these commands on an OAR server

  def generate_oar_properties(options)
    # Reset the OAR API cache, because the rpec tests change the data in our back
    # while calling multiple times this function.
    @@oar_data = {}

    options[:api] ||= {}
    conf = RefRepo::Utils.get_api_config
    options[:api][:user] = conf['username']
    options[:api][:pwd] = conf['password']
    options[:api][:uri] = conf['uri']
    options[:ssh] ||= {}
    options[:ssh][:user] ||= 'g5kadmin'
    options[:ssh][:host] ||= 'oar.%s.g5kadmin'
    options[:sites] = [options[:site]] # for compatibility with other generators

    ############################################
    # Fetch:
    # 1) generated data from load_data_hierarchy
    # 2) oar properties from the reference repository
    ############################################

    # Load the description from the ref-api (data/ dir)
    data_hierarchy = load_data_hierarchy

    # filter based on site/cluster
    site_name = options[:site]

    # Replace the site placeholder of ssh hosts by the site
    options[:ssh][:host] = options[:ssh][:host].gsub('%s', site_name)

    # If no cluster is given, then the clusters are the cluster of the given site
    if !options.key?(:clusters) || options[:clusters].empty?
      if data_hierarchy['sites'].key? site_name
        clusters = data_hierarchy['sites'][site_name]['clusters'].keys
        options[:clusters] = clusters
      else
        raise("The provided site does not exist : I can't detect clusters")
      end
    else
      clusters = options[:clusters]
    end

    # convert to OAR properties
    refrepo_properties = get_oar_properties_from_the_ref_repo(data_hierarchy, {
                                                                sites: [site_name]
                                                              })

    # also fetch the resources hierarchy inside nodes (cores, gpus, etc.)
    generated_hierarchy = extract_clusters_description(clusters,
                                                       site_name,
                                                       options,
                                                       data_hierarchy,
                                                       refrepo_properties[site_name])

    ############################################
    # Output generated information
    ############################################

    ret = 0

    # DO=table
    display_resources_table(generated_hierarchy) if options.key?(:table) && options[:table]

    # Do=Diff
    ret = do_diff(options, generated_hierarchy, refrepo_properties) if options.key?(:diff) && options[:diff]

    # DO=print
    if options.key?(:print) && options[:print]
      cmds = export_rows_as_oar_command(generated_hierarchy, site_name, refrepo_properties[site_name], data_hierarchy)

      puts(cmds)
    end

    # Do=update
    if options[:update]
      printf "Apply changes to the OAR server #{options[:ssh][:host].gsub('%s', site_name)} ? (y/N) "
      prompt = $stdin.gets.chomp
      cmds = export_rows_as_oar_command(generated_hierarchy, site_name, refrepo_properties[site_name], data_hierarchy)
      run_commands_via_ssh(cmds, options) if prompt.downcase == 'y'
    end

    ret
  end
end
include OarProperties
