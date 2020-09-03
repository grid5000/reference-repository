# coding: utf-8

require 'hashdiff'
require 'refrepo/data_loader'
require 'net/ssh'
require 'refrepo/gpu_ref'

class MissingProperty < StandardError; end

MiB = 1024**2

############################################
# Functions related to the "TABLE" operation
############################################

module OarProperties

# OAR API data cache
@@oar_data = {}

def export_rows_as_formated_line(generated_hierarchy)
  # Display header
  puts "+#{'-' * 10} + #{'-' * 20} + #{'-' * 5} + #{'-' * 5} + #{'-' * 8} + #{'-' * 4} + #{'-' * 20} + #{'-' * 30} + #{'-' * 30}+"
  puts "|#{'cluster'.rjust(10)} | #{'host'.ljust(20)} | #{'cpu'.ljust(5)} | #{'core'.ljust(5)} | #{'cpuset'.ljust(8)} | #{'gpu'.ljust(4)} | #{'gpudevice'.ljust(20)} | #{'cpumodel'.ljust(30)} | #{'gpumodel'.ljust(30)}|"
  puts "+#{'-' * 10} + #{'-' * 20} + #{'-' * 5} + #{'-' * 5} + #{'-' * 8} + #{'-' * 4} + #{'-' * 20} + #{'-' * 30} + #{'-' * 30}+"

  oar_rows = generated_hierarchy[:nodes].map{|node| node[:oar_rows]}.flatten

  # Display rows
  oar_rows.each do |row|
    cluster = row[:cluster].to_s
    host = row[:host].to_s
    cpu = row[:cpu].to_s
    core = row[:core].to_s
    cpuset = row[:cpuset].to_s
    gpu = row[:gpu].to_s
    gpudevice = row[:gpudevice].to_s
    cpumodel = row[:cpumodel].to_s
    gpumodel = row[:gpumodel].to_s
    puts "|#{cluster.rjust(10)} | #{host.ljust(20)} | #{cpu.ljust(5)} | #{core.ljust(5)} | #{cpuset.ljust(8)} | #{gpu.ljust(4)} | #{gpudevice.ljust(20)} | #{cpumodel.ljust(30)} | #{gpumodel.ljust(30)}|"
  end
  # Display footer
  puts "+#{'-' * 10} + #{'-' * 20} + #{'-' * 5} + #{'-' * 5} + #{'-' * 8} + #{'-' * 4} + #{'-' * 20} + #{'-' * 30} + #{'-' * 30}+"
end

############################################
# Functions related to the "PRINT" operation
############################################

# Generates an ASCII separator
def generate_separators()
  command = "echo '================================================================================'"
  return command + "\n"
end

def generate_create_disk_cmd(host, disk)
  disk_exist = "disk_exist '#{host}' '#{disk}'"
  command = "echo; echo 'Adding disk #{disk} on host #{host}:'\n"
  command += "#{disk_exist} && echo '=> disk already exists'\n"
  command += "#{disk_exist} || oarnodesetting -a -h '' -p host='#{host}' -p type='disk' -p disk='#{disk}'"
  return command + "\n\n"
end

def generate_set_node_properties_cmd(host, default_properties)
  if not default_properties.nil?
    return '' if default_properties.size == 0
    command  = "echo; echo 'Setting properties for #{host}:'; echo\n"
    command += "oarnodesetting --sql \"host='#{host}' and type='default'\" -p "
    command += properties_internal(default_properties)
    return command + "\n\n"
  else
    return "echo ; echo 'Not setting properties for #{host}: node is not available in ref-api (retired?)'; echo\n\n"
  end
end

def generate_set_disk_properties_cmd(host, disk, disk_properties)
  return '' if disk_properties.size == 0
  command = "echo; echo 'Setting properties for disk #{disk} on host #{host}:'; echo\n"
  command += "oarnodesetting --sql \"host='#{host}' and type='disk' and disk='#{disk}'\" -p "
  command += disk_properties_internal(disk_properties)
  return command + "\n\n"
end

def generate_create_oar_property_cmd(properties_keys)
  command = ''
  ignore_keys_list = ignore_default_keys()
  properties_keys.each do |key, key_type|
    if ignore_keys_list.include?(key)
      next
    end
    # keys such as deploy or besteffort are default OAR keys that should not be created
    if oar_system_keys.include?(key)
      next
    end
    if key_type == Integer
      command += "property_exist '#{key}' || oarproperty -a #{key}\n"
    elsif key_type == String
      command += "property_exist '#{key}' || oarproperty -a #{key} --varchar\n"
    else
      raise "Error: the type of the '#{key}' property is unknown (Integer/String). Cannot generate the corresponding 'oarproperty' command. You must create this property manually ('oarproperty -a #{key} [--varchar]')"
    end
  end
  return command
end


# Generates helper functions:
#   - property_exist : check if a property exists
#   - node_exist : check if a node exists
#   - disk_exist : check if a disk exists
#
# and variables which help to add nex resources:
#   - NEXT_AVAILABLE_CPU_ID : the next identifier that can safely be used for a new cpi
#   - NEXT_AVAILABLE_CORE_ID : the next identifier that can safely be used for a new core
def generate_oar_commands_header()
  return %Q{
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
  commands = %Q{
#############################################
# Create OAR properties that were created by 'oar_resources_add'
#############################################
property_exist 'host' || oarproperty -a host --varchar
property_exist 'cpu' || oarproperty -a cpu
property_exist 'core' || oarproperty -a core
property_exist 'gpudevice' || oarproperty -a gpudevice
property_exist 'gpu' || oarproperty -a gpu
property_exist 'gpu_model' || oarproperty -a gpu_model --varchar

}

  #############################################
  # Create remaining properties (from API)
  #############################################
  commands += %Q{
#############################################
# Create OAR properties if they don't exist
#############################################

}

  # Fetch oar properties from ref repo
  # global_hash = load_data_hierarchy
  global_hash = data_hierarchy
  site_properties = get_oar_properties_from_the_ref_repo(global_hash, {
      :sites => [site_name]
  })[site_name]
  property_keys = get_property_keys(site_properties)

  # Generate OAR commands for creating properties
  commands += generate_create_oar_property_cmd(property_keys)

  return commands
end


# Exports a description of OAR ressources as a bunch of "self contained" OAR
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
def export_rows_as_oar_command(generated_hierarchy, site_name, site_properties, data_hierarchy, faulty_resources=nil, faulty_nodes=nil)

  result = ""

  print_header = true

  if not faulty_nodes.nil? or not faulty_resources.nil?
    print_header = false
  end

  if print_header
    # Generate helper functions and detect the next available CPU and CORE IDs for
    # non exisiting resources
    result += generate_oar_commands_header()

    # Ensure that OAR properties exist before creating/updating OAR resources
    result += generate_oar_property_creation(site_name, data_hierarchy)
  end

  # Iterate over nodes of the generated resource hierarchy
  generated_hierarchy[:nodes].each do |node|

    print_node_header = true

    if not faulty_nodes.nil? and not faulty_nodes.include?(node[:fqdn])
      print_node_header = false
    end

    if print_node_header
      result += %Q{

###################################
# #{node[:fqdn]}
###################################
}
    end

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

      if not faulty_resources.nil? and not faulty_resources.include?(resource_id)
        next
      end

      if resource_id == -1 or resource_id.nil?
        # Add the resource to the OAR DB
        if gpu == ''
          result += "oarnodesetting -a -h '#{host}' -p host='#{host}' -p cpu=#{cpu} -p core=#{core} -p cpuset=#{cpuset}\n"
        else
          result += "oarnodesetting -a -h '#{host}' -p host='#{host}' -p cpu=#{cpu} -p core=#{core} -p cpuset=#{cpuset} -p gpu=#{gpu} -p gpu_model='#{gpumodel}' -p gpudevice=#{gpudevice} # This GPU is mapped on #{gpudevicepath}\n"
        end
      else
        # Update the resource
        if gpu == ''
          result += "oarnodesetting --sql \"host='#{host}' AND resource_id='#{resource_id}' AND type='default'\" -p cpu=#{cpu} -p core=#{core} -p cpuset=#{cpuset}\n"
        else
          result += "oarnodesetting --sql \"host='#{host}' AND resource_id='#{resource_id}' AND type='default'\" -p cpu=#{cpu} -p core=#{core} -p cpuset=#{cpuset} -p gpu=#{gpu} -p gpu_model='#{gpumodel}' -p gpudevice=#{gpudevice} # This GPU is mapped on #{gpudevicepath}\n"
        end
      end
    end

    print_node = true
    if not faulty_nodes.nil? and not faulty_nodes.include?(node[:name])
      print_node = false
    end

    if print_node
      # Set the OAR properties of the OAR node
      result += generate_set_node_properties_cmd(node[:fqdn], node[:default_description])
    end

    # Iterate over storage devices
    node[:description]["storage_devices"].select{|v| v.key?("reservation") and v["reservation"]}.each do |storage_device|
      # As <storage_device> is an Array, where the first element is the device name (i.e. sda, sdb, ...),
      # and the second element is a dictionnary containing information about the storage device,
      # thus two variables are created:
      #    - <storage_device_name> : variable that contains the device name (sda, sdb, ...)
      #    - <storage_device_name_with_hostname> : variable that will be the ID of the storage. It follows this
      #       pattern : "sda1.ecotype-48"
      storage_device_name = storage_device["device"]
      storage_device_name_with_hostname = "#{storage_device_name}.#{node[:name]}"

      if not faulty_nodes.nil? and not faulty_nodes.include?(storage_device_name_with_hostname)
        next
      end

      # Retried the site propertie that corresponds to this storage device
      storage_device_oar_properties_tuple = site_properties["disk"].select { |keys| keys.include?(storage_device_name_with_hostname) }.first

      if storage_device_oar_properties_tuple.nil? or storage_device_oar_properties_tuple.size < 2
        raise "Error: could not find a site properties for disk #{storage_device_name_with_hostname}"
      end
      storage_device_oar_properties = storage_device_oar_properties_tuple[1]

      result += generate_separators()

      # Ensure that the storage device exists
      result += generate_create_disk_cmd(node[:fqdn], storage_device_name_with_hostname)

      # Set the OAR properties associated to this storage device
      result += generate_set_disk_properties_cmd(node[:fqdn], storage_device_name_with_hostname, storage_device_oar_properties)
    end

    if print_node
      result += generate_separators()
    end
  end

  return result
end

############################################
# Functions related to the "DIFF" operation
############################################

def get_ids(host)
  node_uid, site_uid, grid_uid, _tdl = host.split('.')
  cluster_uid, node_num = node_uid.split('-')
  ids = { 'node_uid' => node_uid, 'site_uid' => site_uid, 'grid_uid' => grid_uid, 'cluster_uid' => cluster_uid, 'node_num' => node_num }
  return ids
end

# Get all node properties of a given site from the reference repo hash
# See also: https://www.grid5000.fr/mediawiki/index.php/Reference_Repository
def get_ref_default_properties(_site_uid, site)
  properties = {}
  site['clusters'].each do |cluster_uid, cluster|
    cluster['nodes'].each do |node_uid, node|
      begin
        properties[node_uid] = get_ref_node_properties_internal(cluster_uid, cluster, node_uid, node)
      rescue MissingProperty => e
        puts "Error (missing property) while processing node #{node_uid}: #{e}"
      rescue StandardError => e
        puts "FATAL ERROR while processing node #{node_uid}: #{e}"
        puts "Description of the node is:"
        pp node
        raise
      end
    end
  end
  return properties
end

def get_ref_disk_properties(site_uid, site)
  properties = {}
  site['clusters'].each do |cluster_uid, cluster|
    cluster['nodes'].each do |node_uid, node|
      begin
        properties.merge!(get_ref_disk_properties_internal(site_uid, cluster_uid, cluster, node_uid, node))
      rescue MissingProperty => e
        puts "Error while processing node #{node_uid}: #{e}"
      end
    end
  end
  return properties
end

# Generates the properties of a single node
def get_ref_node_properties_internal(cluster_uid, cluster, node_uid, node)
  h = {}

  if node['status'] == 'retired'
    # For dead nodes, additional information is most likely missing
    # from the ref-repository: just return the state
    h['state'] = 'Dead'
    return h
  end

  main_network_adapter = node['network_adapters'].find { |na| /^eth[0-9]*$/.match(na['device']) && na['enabled'] && na['mounted'] && !na['management'] }

  raise MissingProperty, "Node #{node_uid} does not have a main network_adapter (ie. an ethernet interface with enabled=true && mounted==true && management==false)" unless main_network_adapter

  h['ip'] = main_network_adapter['ip']
  raise MissingProperty, "Node #{node_uid} has no IP" unless h['ip']
  h['cluster'] = cluster_uid
  h['nodemodel'] = cluster['model']
  h['switch'] = main_network_adapter['switch']
  h['besteffort'] = node['supported_job_types']['besteffort']
  h['deploy'] = node['supported_job_types']['deploy']
  h['virtual'] = node['supported_job_types']['virtual']
  h['cpuarch'] = node['architecture']['platform_type']
  h['cpucore'] = node['architecture']['nb_cores'] / node['architecture']['nb_procs']
  h['cputype'] = [node['processor']['model'], node['processor']['version']].join(' ')
  h['cpufreq'] = node['processor']['clock_speed'] / 1_000_000_000.0
  h['disktype'] = (node['storage_devices'].first || {})['interface']
  h['chassis'] = [node['chassis']['manufacturer'], node['chassis']['name'], node['chassis']['serial']].join(' ')

  # ETH
  ni_mountable = node['network_adapters'].select { |na| /^eth[0-9]*$/.match(na['device']) && (na['enabled'] == true && (na['mounted'] == true || na['mountable'] == true)) }
  ni_fastest   = ni_mountable.max_by { |na| na['rate'] || 0 }

  h['eth_count'] = ni_mountable.length
  h['eth_rate']  = ni_fastest['rate'] / 1_000_000_000

  puts "#{node_uid}: Warning - no rate info for the eth interface" if h['eth_count'] > 0 && h['eth_rate'] == 0

  # INFINIBAND
  ni_mountable = node['network_adapters'].select { |na| /^ib[0-9]*(\.[0-9]*)?$/.match(na['device']) && (na['interface'] == 'InfiniBand' and na['enabled'] == true && (na['mounted'] == true || na['mountable'] == true)) }
  ni_fastest   = ni_mountable.max_by { |na| na['rate'] || 0 }
  ib_map = { 0 => 'NO', 10 => 'SDR', 20 => 'DDR', 40 => 'QDR', 56 => 'FDR', 100 => 'EDR' }

  h['ib_count'] = ni_mountable.length
  h['ib_rate']  = ni_mountable.length > 0 ? ni_fastest['rate'] / 1_000_000_000 : 0
  h['ib'] = ib_map[h['ib_rate']]

  puts "#{node_uid}: Warning - unkwnon ib kind for rate #{h['ib_rate']}, update ib_map variable" if not ib_map.key?(h['ib_rate'])
  puts "#{node_uid}: Warning - no rate info for the ib interface" if h['ib_count'] > 0 && h['ib_rate'] == 0

  # OMNIPATH
  ni_mountable = node['network_adapters'].select { |na| /^ib[0-9]*(\.[0-9]*)?$/.match(na['device']) && (na['interface'] == 'Omni-Path' and na['enabled'] == true && (na['mounted'] == true || na['mountable'] == true)) }
  ni_fastest   = ni_mountable.max_by { |na| na['rate'] || 0 }

  h['opa_count'] = ni_mountable.length
  h['opa_rate']  = ni_mountable.length > 0 ? ni_fastest['rate'] / 1_000_000_000 : 0

  puts "#{node_uid}: Warning - no rate info for the opa interface" if h['opa_count'] > 0 && h['opa_rate'] == 0


  # MYRINET
  ni_mountable = node['network_adapters'].select { |na| /^myri[0-9]*$/.match(na['device']) && (na['enabled'] == true && (na['mounted'] == true || na['mountable'] == true)) }
  ni_fastest   = ni_mountable.max_by { |na| na['rate'] || 0 }
  myri_map = { 0 => 'NO', 2 => 'Myrinet-2000', 10 => 'Myri-10G' }

  h['myri_count'] = ni_mountable.length
  h['myri_rate']  = ni_mountable.length > 0 ? ni_fastest['rate'] / 1_000_000_000 : 0
  h['myri'] = myri_map[h['myri_rate']]

  puts "#{node_uid}: Warning - no rate info for the myri interface" if h['myri_count'] > 0 && h['myri_rate'] == 0

  h['memcore'] = node['main_memory']['ram_size'] / node['architecture']['nb_cores']/MiB
  h['memcpu'] = node['main_memory']['ram_size'] / node['architecture']['nb_procs']/MiB
  h['memnode'] = node['main_memory']['ram_size'] / MiB

  if node.key?('gpu_devices') \
    and h['cluster'] != 'orion'
    # Do not generate GPU ppty for orion, cf #10785

    # This forbids a node to host different GPU models ...
    h['gpu_model'] = GPURef.getGrid5000LegacyNameFor(node['gpu_devices'].values[0]['model'])
    h['gpu_count'] = node['gpu_devices'].length
  else
    h['gpu_model'] = false
    h['gpu_count'] = 0
  end

  if node.key?('exotic')
    h['exotic'] = node['exotic']
  else
    h['exotic'] = false
  end

  h['mic'] = if node['mic']
               'YES'
             else
               'NO'
             end

  node['monitoring'] ||= {}
  h['wattmeter'] = case node['monitoring']['wattmeter']
                   when "true" then true
                   when "false" then false
                   when nil then false
                   else node['monitoring']['wattmeter'].upcase
                   end

  h['cluster_priority'] = (cluster['priority'] || Time.parse(cluster['created_at'].to_s).strftime('%Y%m')).to_i

  h['max_walltime'] = 0 # default
  h['max_walltime'] = node['supported_job_types']['max_walltime'] if node['supported_job_types'] && node['supported_job_types'].has_key?('max_walltime')

  h['production'] = get_production_property(node)
  h['maintenance'] = get_maintenance_property(node)

  # Disk reservation
  h['disk_reservation_count'] = node['storage_devices'].select { |v| v['reservation'] }.length

  # convert booleans to YES/NO string
  h.each do |k, v|
    if v == true
      h[k] = 'YES'
    elsif v == false
      h[k] = 'NO'
    elsif v.is_a? Float
      h[k] = v.to_s
    end
  end

  return h
end

def get_production_property(node)
  production = false # default
  production = node['supported_job_types']['queues'].include?('production') if node['supported_job_types'] && node['supported_job_types'].has_key?('queues')
  production = production == true ? 'YES' : 'NO'
  return production
end

def get_maintenance_property(node)
  maintenance = false # default
  maintenance = node['supported_job_types']['queues'].include?('testing') if node['supported_job_types'] && node['supported_job_types'].has_key?('queues')
  maintenance = maintenance == true ? 'YES' : 'NO'
  return maintenance
end

# Return a list of properties as a hash: { property1 => String, property2 => Integer, ... }
# We detect the type of the property (Integer/String) by looking at the existing values
def get_property_keys(properties)
  properties_keys = {}
  properties.each do |type, type_properties|
    properties_keys.merge!(get_property_keys_internal(type, type_properties))
  end
  return properties_keys
end

def properties_internal(properties)
  str = properties
            .to_a
            .select{|k, v| not ignore_default_keys.include? k}
            .map do |(k, v)|
                v = "YES" if v == true
                v = "NO"  if v == false
                !v.nil? ? "#{k}=#{v.inspect.gsub("'", "\\'").gsub("\"", "'")}" : nil
            end.compact.join(' -p ')
  return str
end

def disk_properties_internal(properties)
  str = properties
            .to_a
            .select{|k, v| not v.nil? and not v==""}
            .map do |(k, v)|
    v = "YES" if v == true
    v = "NO"  if v == false
    !v.nil? ? "#{k}=#{v.inspect.gsub("'", "\\'").gsub("\"", "'")}" : nil
  end.compact.join(' -p ')
  return str
end

# Returns the expected properties of the reservable disks. These
# properties are then compared with the values in OAR database, to
# generate a diff.
# The key is of the form [node, disk]. In the following example
# we list the different disks (from sdb to sdf) of node grimoire-1.
# {["grimoire-1", "sdb.grimoire-1"]=>
#  {"cluster"=>"grimoire",
#  "host"=>"grimoire-1.nancy.grid5000.fr",
#  "network_address"=>"",
#  "available_upto"=>0,
#  "deploy"=>"YES",
#  "production"=>"NO",
#  "maintenance"=>"NO",
#  "disk"=>"sdb.grimoire-1",
#  "diskpath"=>"/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:1:0",
#  "cpuset"=>-1},
#  ["grimoire-1", "sdc.grimoire-1"]=> ...
def get_ref_disk_properties_internal(site_uid, cluster_uid, cluster, node_uid, node)
  properties = {}
  node['storage_devices'].each_with_index do |device, index|
    disk = [device['device'], node_uid].join('.')
    if index > 0 && device['reservation'] # index > 0 is used to exclude sda
      key = [node_uid, disk]
      # Starting from default resources properties, then override with disk properties
      h = get_ref_node_properties_internal(cluster_uid, cluster, node_uid, node)
      node_address = [node_uid, site_uid, 'grid5000.fr'].join('.')
      h['host'] = node_address
      h['network_address'] = ''
      h['available_upto'] = 0
      h['deploy'] = 'YES'
      h['max_walltime'] = 0
      h['disk'] = disk
      h['diskpath'] = device['by_path']
      h['cpuset'] = -1
      properties[key] = h
    end
  end
  properties
end

def get_oar_default_properties(site_uid, options)
  oarnodes = get_oar_data(site_uid, options)
  oarnodes = oarnodes.select { |v| v['type'] == 'default' }.map { |v| [get_ids(v['host'])['node_uid'], v] }.to_h
  return oarnodes
end

def get_oar_disk_properties(site_uid, options)
  oarnodes = get_oar_data(site_uid, options)
  oarnodes = oarnodes.select { |v| v['type'] == 'disk' }.map { |v| [[get_ids(v['host'])['node_uid'], v['disk']], v] }.to_h
  return oarnodes
end

# Get all data from the OAR database
def get_oar_data(site_uid, options)
  data_key = [site_uid,options].to_s
  # is data already in cache ?
  if @@oar_data[data_key].nil?
    # If no API URL is given, set a default URL on https://api.grid5000.fr
    if not options[:api][:uri]
      options[:api][:uri] = "https://api.grid5000.fr"
    end

    # Preparing the URL that will be used to fetch OAR resources
    if options[:api][:uri].include? "api.grid5000.fr"
      api_uri = URI.parse('https://api.grid5000.fr/stable/sites/' + site_uid  + '/internal/oarapi/resources/details.json?limit=999999')
    elsif options[:api][:uri].include? "api-ext.grid5000.fr"
      api_uri = URI.parse('https://api-ext.grid5000.fr/stable/sites/' + site_uid  + '/internal/oarapi/resources/details.json?limit=999999')
    else
      api_uri = URI.parse(options[:api][:uri]+'/oarapi/resources/details.json?limit=999999')
    end

    # Download the OAR properties from the OAR API (through G5K API)
    puts "Downloading resources properties from #{api_uri} ..." if options[:verbose] and options[:verbose] > 0
    http = Net::HTTP.new(api_uri.host, api_uri.port)
    if api_uri.scheme == "https"
      http.use_ssl = true
    end
    request = Net::HTTP::Get.new(api_uri.request_uri, {'User-Agent' => 'reference-repository/gen/oar-properties'})

    # For outside g5k network access
    if options[:api][:user] && options[:api][:pwd]
      request.basic_auth(options[:api][:user], options[:api][:pwd])
    end

    response = http.request(request)
    raise "Failed to fetch resources properties from API: \n#{response.body}\n" unless response.code.to_i == 200
    puts '... done' if options[:verbose] and options[:verbose] > 0

    oarnodes = JSON.parse(response.body)

    # Adapt from the format of the OAR API
    oarnodes = oarnodes['items'] if oarnodes.key?('items')
    @@oar_data[data_key] = oarnodes
  end
  # Return a deep copy of the cached value as it will be modified in place
  return Marshal.load(Marshal.dump(@@oar_data[data_key]))
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
      next if NilClass === v
      # also skip detection if 'v == false' because it seems that if a varchar property
      # only as 'NO' values, it might be interpreted as a boolean
      # (see the ib property at nantes: ib: NO in the YAML instead of ib: 'NO')
      next if v == false
      properties_keys[k] = v.class
    end
  end
  return properties_keys
end

def diff_properties(type, properties_oar, properties_ref)
  properties_oar ||= {}
  properties_ref ||= {}

  if type == 'default'
    ignore_keys = ignore_keys()
  elsif type == 'disk'
    check_keys = %w(cluster host network_address available_upto deploy production maintenance disk diskpath cpuset)
    ignore_keys = ignore_keys() - check_keys #Some key must be ignored for default but not for disks, ex: available_upto
  end
  ignore_keys.each { |key| properties_oar.delete(key) }
  ignore_keys.each { |key| properties_ref.delete(key) }

  # Ignore the 'state' property only if the node is not 'Dead' according to
  # the reference-repo.
  # Otherwise, we must enforce that the node state is also 'Dead' on the OAR server.
  # On the OAR server, the 'state' property can be modified by phoenix. We ignore that.
  if type == 'default' && properties_ref['state'] != 'Dead'
    properties_oar.delete('state')
    properties_ref.delete('state')
  elsif type == 'default' && properties_ref.size == 1
    # For dead nodes, when information is missing from the reference-repo, only enforce the 'state' property and ignore other differences.
    return Hashdiff.diff({'state' => properties_oar['state']}, {'state' => properties_ref['state']})
  end

  return Hashdiff.diff(properties_oar, properties_ref)
end

# These keys will not be created neither compared with the -d option
# ignore_default_keys is only applied to resources of type 'default'
def ignore_default_keys()
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
  ignore_default_keys = [
    "slash_16",
    "slash_17",
    "slash_18",
    "slash_19",
    "slash_20",
    "slash_21",
    "slash_22",
    "available_upto",
    "chunks",
    "comment", # TODO
    "core", # This property was created by 'oar_resources_add'
    "cpu", # This property was created by 'oar_resources_add'
    "host", # This property was created by 'oar_resources_add'
    "gpudevice", # New property taken into account by the new generator
    "gpu_model", # New property taken into account by the new generator
    "gpu", # New property taken into account by the new generator
    "cpuset",
    "desktop_computing",
    "drain",
    "expiry_date",
    "finaud_decision",
    "grub",
    "jobs", # This property exists when a job is running
    "last_available_upto",
    "last_job_date",
    "network_address", # TODO
    "next_finaud_decision",
    "next_state",
    "rconsole", # TODO
    "resource_id",
    "scheduler_priority",
    "state",
    "state_num",
    "subnet_address",
    "subnet_prefix",
    "suspended_jobs",
    "thread",
    "type", # TODO
    "vlan",
    "pdu",
    "id", # id from API (= resource_id from oarnodes)
    "api_timestamp", # from API
    "links", # from API
  ]
  return ignore_default_keys
end

# Properties of resources of type 'disk' to ignore (for example, when
# comparing resources of type 'default' with the -d option)
def ignore_disk_keys()
  ignore_disk_keys = [
    "disk",
    "diskpath"
  ]
  return ignore_disk_keys
end

def ignore_keys()
  return ignore_default_keys() + ignore_disk_keys()
end

# Properties such as deploy and besteffort, that should not be created
def oar_system_keys()
  [
    'deploy',
    'besteffort'
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
def run_commands_via_ssh(cmds, options, verbose=true)
  # The following is equivalent to : "cat cmds | bash"
  res = ""
  c = Net::SSH.start(options[:ssh][:host], options[:ssh][:user])
  c.open_channel { |channel|
    channel.exec('sudo bash') { |ch, success|
      # stdout
      channel.on_data { |ch2, data|
        if verbose
          puts data
        end
        res += data
      }
      # stderr
      channel.on_extended_data do |ch2, type, data|
        if verbose
          puts data
        end
        res += data
      end

      channel.send_data cmds
      channel.eof!
    }
  }
  c.loop
  c.close
  return res
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
  ret = 0

  diagnostic_msgs = []

  faulty_resources = []
  faulty_nodes = []

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

  # Diff
  if options[:diff]
    # Build the list of nodes that are listed in properties['oar'],
    # but does not exist in properties['ref']
    # We distinguish 'Dead' nodes and 'Alive'/'Absent'/etc. nodes
    missings_alive = []
    missings_dead = []
    properties['oar'].each do |site_uid, site_properties|
      site_properties['default'].each_filtered_node_uid(options[:clusters], options[:nodes]) do |node_uid, node_properties_oar|
        unless properties['ref'][site_uid]['default'][node_uid]
          node_properties_oar['state'] != 'Dead' ? missings_alive << node_uid : missings_dead << node_uid
        end
      end
    end

    if missings_alive.size > 0
      diagnostic_msgs.push("*** Error: The following nodes exist in the OAR server but are missing in the reference-repo: #{missings_alive.join(', ')}.\n")
      ret = false unless options[:update] || options[:print]
    end

    skipped_nodes = []
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
          node_uid, = key

          if properties_ref['state'] == 'Dead'
            skipped_nodes << node_uid
            next
          end

          properties_oar = properties['oar'][site_uid][type][key]

          diff = diff_properties(type, properties_oar, properties_ref) # Note: this deletes some properties from the input parameters
          diff_keys = diff.map { |hashdiff_array| hashdiff_array[1] }
          properties['diff'][site_uid][type][key] = properties_ref.select { |k, _v| diff_keys.include?(k) }

          if not diff.empty?
            if key.kind_of?(Array)
              faulty_nodes.push(key[-1])
            else
              faulty_nodes.push(key)
            end
          end

          # Verbose output
          if properties['oar'][site_uid][type][key].nil?
            info = ((type == 'default') ? ' new node !' : ' new disk !')
          else
            info = ''
          end

          case options[:verbose]
          when 1
            diagnostic_msgs.push( "#{key}:#{info}") if info != ''
            diagnostic_msgs.push( "#{key}:#{diff_keys}") if diff.size != 0
          when 2
            # Give more details
            if header == false
              diagnostic_msgs.push( "Output format: [ '-', 'key', 'value'] for missing, [ '+', 'key', 'value'] for added, ['~', 'key', 'old value', 'new value'] for changed")
              header = true
            end
            if diff.empty?
              diagnostic_msgs.push( "  #{key}: OK#{info}")
            elsif diff == prev_diff
              diagnostic_msgs.push( "  #{key}:#{info} same modifications as above")
            else
              diagnostic_msgs.push( "  #{key}:#{info}")
              diff.each { |d| diagnostic_msgs.push( "    #{d}") }
            end
            prev_diff = diff
          when 3
            # Even more details
            diagnostic_msgs.push( "#{key}:#{info}") if info != ''
            diagnostic_msgs.push( JSON.pretty_generate(key => { 'old values' => properties_oar, 'new values' => properties_ref }))
          end
          if diff.size != 0
            ret = false unless options[:update] || options[:print]
          end
        end
      end

      # Get the list of property keys from the OAR scheduler (['oar'])
      properties_keys['oar'][site_uid] = get_property_keys(properties['oar'][site_uid])

      # Build the list of properties that must be created in the OAR server
      properties_keys['diff'][site_uid] = {}
      properties_keys['ref'][site_uid].each do |k, v_ref|
        v_oar = properties_keys['oar'][site_uid][k]
        properties_keys['diff'][site_uid][k] = v_ref unless v_oar
        if v_oar && v_oar != v_ref && v_ref != NilClass && v_oar != NilClass
          # Detect inconsistency between the type (String/Integer) of properties generated by this script and the existing values on the server.
          diagnostic_msgs.push( "Error: the OAR property '#{k}' is a '#{v_oar}' on the #{site_uid} server and this script uses '#{v_ref}' for this property.")
          ret = false unless options[:update] || options[:print]
        end
      end

      diagnostic_msgs.push( "Properties that need to be created on the #{site_uid} server: #{properties_keys['diff'][site_uid].keys.to_a.delete_if { |e| ignore_keys.include?(e) }.join(', ')}") if options[:verbose] && properties_keys['diff'][site_uid].keys.to_a.delete_if { |e| ignore_keys.include?(e) }.size > 0

      # Detect unknown properties
      unknown_properties = properties_keys['oar'][site_uid].keys.to_set - properties_keys['ref'][site_uid].keys.to_set
      ignore_default_keys.each do |key|
        unknown_properties.delete(key)
      end

      if options[:verbose] && unknown_properties.size > 0
        diagnostic_msgs.push( "Properties existing on the #{site_uid} server but not managed/known by the generator: #{unknown_properties.to_a.join(', ')}.")
        diagnostic_msgs.push( "Hint: you can delete properties with 'oarproperty -d <property>' or add them to the ignore list in lib/lib-oar-properties.rb.")
        ret = false unless options[:update] || options[:print]
      end
      diagnostic_msgs.push( "Skipped retired nodes: #{skipped_nodes}") if skipped_nodes.any?


      if not (options[:print] and options[:diff])
        diagnostic_msgs.map{|msg| puts(msg)}
      end

      # Check that CPUSETs on the OAR server are consistent with what would have been generated
      oar_resources = get_oar_resources_from_oar(options)

      error_msgs = ""

      options[:clusters].each do |cluster|

        generated_rows_for_this_cluster = generated_hierarchy[:nodes]
                                              .map{|node| node[:oar_rows]}
                                              .flatten
                                              .select{|r| r[:cluster] == cluster}

        site_resources = oar_resources[site_uid]["resources"]
        cluster_resources = site_resources.select{|x| x["cluster"] == cluster}
        default_cluster_resources = cluster_resources.select{|r| r["type"] == "default"}


        if generated_rows_for_this_cluster.length > 0
          # Check that OAR resources are associated with the right cpu, core and cpuset
          generated_rows_for_this_cluster.each do |row|
            corresponding_resource = default_cluster_resources.select{|r| r["id"] == row[:resource_id]}
            if corresponding_resource.length > 0
              resc = corresponding_resource[0]

              {:cpu => "cpu", :core => "core", :cpuset => "cpuset", :gpu => "gpu", :gpudevice => "gpudevice"}.each do |key, value|
                if row[key].to_s != corresponding_resource[0][value].to_s and not (key == :gpu and row[key].nil? and corresponding_resource[0][value] == 0)
                  expected_value = row[key]
                  if expected_value == "" or expected_value.nil?
                    expected_value = "ø"
                  end
                  diagnostic_msg = <<-TXT
# Error: Resource #{resc["id"]} (host=#{resc["network_address"]} cpu=#{resc["cpu"]} core=#{resc["core"]} cpuset=#{resc["cpuset"]} gpu=#{resc["gpu"]} gpudevice=#{resc["gpudevice"]}) has a mismatch for ressource #{value.upcase}: OAR API gives #{resc[value]}, generator wants #{expected_value}.
TXT
                  error_msgs += "#{diagnostic_msg}"
                  faulty_resources.push(row[:resource_id])
                  faulty_resources.push(row[:host])
                end
              end
            else
              # If resource_id is not equal to -1, then the generator is working on a resource that should exist,
              # however it cannot be found : the generator reports an error to the operator
              if row[:resource_id] != -1
                puts "Error: could not find ressource with ID=#{row[:resource_id]}"
                faulty_resources.push(row[:resource_id])
                faulty_resources.push(row[:host])
              end
            end
          end
        end
      end

      if not (options[:print] and options[:diff]) and not error_msgs.empty?
        puts error_msgs
        ret = false unless options[:update] || options[:print]
      end

    end # if options[:diff]
  end

  return ret, faulty_resources, faulty_nodes
end


def sanity_check(cluster_resources, site_resources)

  sanity_result = true

  # Detect cluster resources
  cluster_cpus =
    cluster_resources
      .map{|r| r["cpu"]}
      .uniq
  cluster_gpus =
    cluster_resources
      .map{|r| r["gpu"]}
      .select{|gpu| not gpu.nil?}
      .uniq
  cluster_cores =
    cluster_resources
      .map{|r| r["core"]}
      .uniq

  # Check CPUs
  cluster_cpus.each do |cluster_cpu|
    hosts_with_same_cpu =
      site_resources
        .select{|r| r["cpu"] == cluster_cpu}
        .map{|r| r["host"]}
        .uniq

    if hosts_with_same_cpu.length > 1
      puts("################################")
      puts("# Error: CPU #{cluster_cpu} is associated to more than one host: #{hosts_with_same_cpu}.")
      puts("# You can review this situation via the following command:\n")
      puts("################################")
      puts("oarnodes -Y --sql \"cpu=#{cluster_cpu}\"")
      puts("")

      sanity_result = false
    end
  end

  # Checks GPUs
  cluster_gpus.each do |cluster_gpu|
    hosts_with_same_gpu =
      site_resources
        .select{|r| r["gpu"] == cluster_gpu}
        .map{|r| r["host"]}
        .uniq

    if hosts_with_same_gpu.length > 1
      puts("################################")
      puts("# Error: GPU #{cluster_gpu} is associated to more than one host: #{hosts_with_same_gpu}.")
      puts("# You can review this situation via the following command:\n")
      puts("################################")
      puts("oarnodes -Y --sql \"gpu=#{cluster_gpu}\"")
      puts("")

      sanity_result = false
    end
  end

  # Check Cores
  cluster_cores.each do |cluster_core|
    resources_id_with_same_core =
      site_resources
        .select{|r| r["core"] == cluster_core}
        .map{|r| r["id"]}

    if resources_id_with_same_core.length > 1
      oar_sql_clause = resources_id_with_same_core .map{|rid| "resource_id='#{rid}'"}.join(" OR ")

      puts("################################")
      puts("# Error: resources with ids #{resources_id_with_same_core} have the same value for core (core is equal to #{cluster_core})\n")
      puts("# You can review this situation via the following command:\n")
      puts("################################")
      puts("oarnodes -Y --sql \"#{oar_sql_clause}\"")
      puts("")

      sanity_result = false
    end
  end

  return sanity_result
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
      :nodes => []
  }

  ############################################
  # (2) Generate an OAR node hierarchy
  ############################################

  site_resources = oar_resources[site_name]["resources"].select{|r| r["type"] == "default"}

  next_rsc_ids = {
      "cpu" => site_resources.length > 0 ? site_resources.map{|r| r["cpu"]}.max : 0,
      "core" => site_resources.length > 0 ? site_resources.map{|r| r["core"]}.max : 0,
      "gpu" => site_resources.length > 0 ? site_resources.map{|r| r["gpu"]}.select{|x| not x.nil?}.max : 0
  }

  # Some existing cluster have GPUs, but no GPU ID has been allocated to them
  if next_rsc_ids["gpu"].nil?
    next_rsc_ids["gpu"] = 0
  end

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

    cluster_desc_from_data_files = data_hierarchy['sites'][site_name]['clusters'][cluster_name]
    cluster_nodes = cluster_desc_from_data_files['nodes']

    node_count = cluster_nodes.length

    cluster_resources = site_resources
                            .select{|r| r["cluster"] == cluster_name}
                            .select{|r| cluster_nodes.include?(r["host"].split(".")[0])}
                            .sort_by{|r| [r["cpu"], r["core"]]}

    sanity_check_result = sanity_check(cluster_resources, site_resources)
    unless sanity_check_result
      puts("It seems that the cluster \"#{cluster_name}\" has some incoherence in its resource configuration (see above). The generator will abort.")
      raise 'Sanity check failed'
    end

    first_node = cluster_desc_from_data_files['nodes'].first[1]

    # Some clusters such as graphite have a different organisation:
    # for example, graphite-1 is organised as follow:
    #   1st resource => cpu: 665, core: 1903
    #   2nd resource => cpu: 666, core: 1904
    #   3rd resource => cpu: 665, core: 1905
    #   4th resource => cpu: 666, core: 1906
    #   ...
    #
    # To cope with such cases and ensure an homogeneous processing a "is_quirk_cluster" variable is set to true.
    is_quirk_cluster = false


    cpu_count = first_node['architecture']['nb_procs']
    cpu_core_count = first_node['architecture']['nb_cores'] / cpu_count
    cpu_thread_count = first_node['architecture']['nb_threads'] / cpu_count
    gpu_count = cluster_desc_from_data_files['nodes'].values.map { |e| (e['gpu_devices'] || {} ).length }.max

    cpu_model = "#{first_node['processor']['model']} #{first_node['processor']['version']}"
    core_numbering = first_node['architecture']['cpu_core_numbering']

    ############################################
    # (2-b) Detect existing resource_ids and {CPU, CORE, CPUSET, GPU}'s IDs
    ############################################

    # Detect if the cluster is new, or if it is already known by OAR
    is_a_new_cluster = cluster_resources.select{|x| x["cluster"] == cluster_name}.length == 0

    # <phys_rsc_map> is a hash that centralises variables that will be used for managing IDs of CPUs, COREs, GPUs of
    # the cluster that is going to be updated. <phys_rsc_map> is useful to detect situations where the current number
    # of resources associated to a cluster does not correspond to the needs of the cluster.
    phys_rsc_map = {
        "cpu" => {
          :current_ids => [],
          :per_server_count => cpu_count,
          :per_cluster_count => node_count * cpu_count
        },
        "core" => {
          :current_ids => [],
          :per_server_count => cpu_core_count,
          :per_cluster_count => node_count * cpu_count * cpu_core_count
        },
        "gpu" => {
          :current_ids => [],
          :per_server_count => gpu_count,
          :per_cluster_count =>  cluster_desc_from_data_files['nodes'].values.map { |e| (e['gpu_devices'] || {} ).length }.inject(0) { |a, b| a+b } # sum
        },
    }

    # For each physical ressource, we prepare a list of IDs:
    #   a) if the cluster is new: the IDs is a list of number in [max_resource_id, max_resource_id + cluster_resource_count]
    #   a) if the cluster is not new: the IDs is the list of existing resources
    phys_rsc_map.each do |physical_resource, variables|
      # if it's a new cluster, or the cluster doesn't have resource ids for this kind of resources
      if is_a_new_cluster or cluster_resources.map{|r| r[physical_resource]}.select{|x| not x.nil?}.empty?
        variables[:current_ids] = [*next_rsc_ids[physical_resource]+1..next_rsc_ids[physical_resource]+variables[:per_cluster_count]]
        next_rsc_ids[physical_resource] = variables[:per_server_count] > 0 ? variables[:current_ids].max : next_rsc_ids[physical_resource]
      else
        variables[:current_ids] = cluster_resources.map{|r| r[physical_resource]}.select{|x| not x.nil?}.uniq
      end
    end

    if is_a_new_cluster
      oar_resource_ids = phys_rsc_map["core"][:current_ids].map{|r| -1}
    else
      oar_resource_ids = cluster_resources.map{|r| r["id"]}.uniq
      if oar_resource_ids != cluster_resources.sort_by {|r| [ r["cpu"], r["core"]] }.map{|r| r["id"]}
        is_quirk_cluster = true
      end
    end

    phys_rsc_map.each do |physical_resource, variables|
      # Try to detect case where an existing cluster is misconfigured: too many or too few OAR resources
      phys_rsc_ids = variables[:current_ids]
      expected_phys_rsc_count = variables[:per_cluster_count]

      if phys_rsc_ids.length != expected_phys_rsc_count
        if ["cpu", "core", "gpu"].include? physical_resource
          puts("#{physical_resource.upcase} has an unexpected number of resources (current:#{phys_rsc_ids.length} vs expected:#{expected_phys_rsc_count}).")
          if ["cpu", "core"].include? physical_resource # this problem is not fatal for GPUs
            raise "unexpected number (current:#{phys_rsc_ids.length} vs expected:#{expected_phys_rsc_count}) of resources for cluster #{cluster_name}"
          end
        end
      end

      variables[:current_ids] = phys_rsc_ids
    end

    # Some cluster (econome) have attributed resources according to the "alpha-numerical" order of nodes
    # ([1, 11, 12, ..., 3] instead of [1, 2, 3, 4, ...]). Here we preserve to order of existing nodes of the cluster
    if is_a_new_cluster
      nodes_names = (1..node_count).map {|i| {:name => "#{cluster_name}-#{i}", :fqdn => "#{cluster_name}-#{i}.#{site_name}.grid5000.fr"}}
    else
      nodes_names = cluster_resources.map{|r| r["host"]}.map{|fqdn| {:fqdn => fqdn, :name => fqdn.split(".")[0]}}.uniq
    end

    ############################################
    # Suite of (2-a): Iterate over nodes of the cluster. (rest: cpus, cores)
    ############################################

    (1..node_count).each do |node_num|

      # node_index0 starts at 0
      node_index0 = node_num -1

      name = nodes_names[node_index0][:name]
      fqdn = nodes_names[node_index0][:fqdn]

      node_description = cluster_desc_from_data_files["nodes"][name]

      node_description_default_properties = site_properties["default"][name]

      if node_description.nil?
        next
      end

      generated_node_description = {
        :name => name,
        :fqdn => fqdn,
        :cluster_name => cluster_name,
        :site_name => site_name,
        :description => node_description,
        :oar_rows => [],
        :disks => [],
        :gpus => (node_description["gpu_devices"] != nil ? (node_description["gpu_devices"].select{|k ,v| v.fetch("reservation", true)}.length) : 0),
        :default_description => node_description_default_properties
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
          if not is_quirk_cluster
            cpu_id = phys_rsc_map["cpu"][:current_ids][cpu_idx]
            core_id = phys_rsc_map["core"][:current_ids][core_idx]
          else
            current_resource = cluster_resources.select{|r| r["id"] == oar_resource_id}[0]
            cpu_id = current_resource["cpu"]
            core_id = current_resource["core"]
          end

          # Prepare an Hash that represents a single OAR resource. Few
          # keys are initialized with empty values.
          row = {
            :cluster => cluster_name,
            :host => name,
            :cpu => cpu_id,
            :core => core_id,
            :cpuset => nil,
            :gpu => nil,
            :gpudevice => nil,
            :gpudevicepath => nil,
            :cpumodel => nil,
            :gpumodel => nil,
            :oar_properties => nil,
            :fqdn => fqdn,
            :resource_id => oar_resource_id,
          }

          ############################################
          # (2-d) Associate a cpuset to each core
          ############################################
          if core_numbering == 'contiguous'
            row[:cpuset] = cpu_num * cpu_core_count + core_num
          elsif core_numbering == 'contiguous-including-threads'
            row[:cpuset] = cpu_num * cpu_thread_count + core_num
          elsif core_numbering == 'round-robin'
            row[:cpuset] = cpu_num + core_num * cpu_count
          else
            raise
          end

          row[:cpumodel] = cpu_model

          ############################################
          # (2-e) [if cluster with GPU] Associate a gpuset to each core
          ############################################

          if node_description.key? "gpu_devices"
            # numa_gpus is the list of gpus for the current CPU
            numa_gpus = node_description["gpu_devices"].values.select {|v| v['cpu_affinity'] == cpu_num and v.fetch("reservation", true)}

            if not numa_gpus.empty? # this can happen if GPUs are not reservable
              if numa_gpus.first.key? 'cores_affinity'
                # this cluster uses cores_affinity, not arbitrary allocation
                selected_gpu = numa_gpus.find { |g| g['cores_affinity'].split.map { |e| e.to_i }.include?(row[:cpuset]) }
                if selected_gpu.nil?
                  raise "Could not find a GPU on CPU #{cpu_num} for core #{row[:cpuset]}"
                end
              else
                gpu_idx = core_num / (cpu_core_count / numa_gpus.length)
                selected_gpu = numa_gpus[gpu_idx]
              end
              # id of the selected GPU in the node
              local_id = node_description["gpu_devices"].values.index(selected_gpu)

              # to assign the gpu number, just use the number of nodes and the number of GPUs per node
              # sanity check: we must fall into the correct range
              gpu = phys_rsc_map["gpu"][:current_ids].min + node_index0 * gpu_count + local_id
              if gpu > phys_rsc_map["gpu"][:current_ids].max
                raise "Invalid GPU number for cluster #{cluster_name}"
              end
              row[:gpu] = gpu
              row[:gpudevice] = local_id
              row[:gpudevicepath] = selected_gpu['device']
              row[:gpumodel] = selected_gpu['model']
            end
          end

          core_idx += 1

          generated_node_description[:oar_rows].push(row)
        end
        cpu_idx += 1
      end

      generated_hierarchy[:nodes].push(generated_node_description)
    end
  end
  return generated_hierarchy
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
  # 1) hierarchy from YAML files
  # 2) generated data from load_data_hierarchy
  # 3) oar properties from the reference repository
  ############################################

  data_hierarchy = load_data_hierarchy

  site_name = options[:site]

  # Replace the site placeholder of ssh hosts by the site
  options[:ssh][:host] = options[:ssh][:host].gsub('%s', site_name)

  # If no cluster is given, then the clusters are the cluster of the given site
  if not options.key? :clusters or options[:clusters].length == 0
    if data_hierarchy['sites'].key? site_name
      clusters = data_hierarchy['sites'][site_name]['clusters'].keys
      options[:clusters] = clusters
    else
      raise("The provided site does not exist : I can't detect clusters")
    end
  else
    clusters = options[:clusters]
  end

  refrepo_properties = get_oar_properties_from_the_ref_repo(data_hierarchy, {
      :sites => [site_name]
  })

  ############################################
  # Generate information about the clusters
  ############################################

  begin
    generated_hierarchy = extract_clusters_description(clusters,
                                                       site_name,
                                                       options,
                                                       data_hierarchy,
                                                       refrepo_properties[site_name])
  rescue
    puts "A problem occured while building the clusters description. Generator is exiting."
    puts $!
    puts $@
    return 1
  end

  ############################################
  # Output generated information
  ############################################

  ret = 0

  # DO=table
  if options.key? :table and options[:table]
    export_rows_as_formated_line(generated_hierarchy)
  end

  # Do=Diff
  if options.key? :diff and options[:diff]
    return_code, faulty_resources, faulty_nodes = do_diff(options, generated_hierarchy, refrepo_properties)
    ret = return_code
  end

  # DO=print
  if options.key? :print and options[:print]
    if options[:diff]
      cmds = export_rows_as_oar_command(generated_hierarchy, site_name, refrepo_properties[site_name], data_hierarchy, faulty_resources, faulty_nodes)
    else
      cmds = export_rows_as_oar_command(generated_hierarchy, site_name, refrepo_properties[site_name], data_hierarchy)
    end

    puts(cmds)
  end


  # Do=update
  if options[:update]
    printf 'Apply changes to the OAR server ' + options[:ssh][:host].gsub('%s', site_name) + ' ? (y/N) '
    prompt = STDIN.gets.chomp
    cmds = export_rows_as_oar_command(generated_hierarchy, site_name, refrepo_properties[site_name], data_hierarchy)
    run_commands_via_ssh(cmds, options) if prompt.downcase == 'y'
  end

  return ret
end

end
include OarProperties
