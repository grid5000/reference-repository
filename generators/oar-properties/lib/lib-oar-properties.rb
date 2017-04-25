#!/usr/bin/ruby
# coding: utf-8

require 'pp'
require 'erb'
require 'fileutils'
require 'pathname'
require 'json'
require 'time'
require 'yaml'
require 'hashdiff'
require 'set'
require 'uri'
require 'net/https'

class MissingProperty < StandardError; end

MiB = 1024**2

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
        puts "Error while processing node #{node_uid}: #{e}"
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
        properties.merge!(get_ref_disk_properties_internal(site_uid, cluster_uid, node_uid, node))
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

  main_network_adapter = node['network_adapters'].find { |k, na| /^eth[0-9]*$/.match(k) && na['enabled'] && na['mounted'] && !na['management'] }
  raise MissingProperty, "Node #{node_uid} does not have a main network_adapter (ie. an ethernet interface with enabled=true && mounted==true && management==false)" unless main_network_adapter

  h['ip'] = main_network_adapter[1]['ip']
  raise MissingProperty, "Node #{node_uid} has no IP" unless h['ip']
  h['cluster'] = cluster_uid
  h['nodemodel'] = cluster['model']
  h['switch'] = main_network_adapter[1]['switch']
  h['besteffort'] = node['supported_job_types']['besteffort']
  h['deploy'] = node['supported_job_types']['deploy']
  h['virtual'] = node['supported_job_types']['virtual']
  h['cpuarch'] = node['architecture']['platform_type']
  h['cpucore'] = node['architecture']['nb_cores'] / node['architecture']['nb_procs']
  h['cputype'] = [node['processor']['model'], node['processor']['version']].join(' ')
  h['cpufreq'] = node['processor']['clock_speed'] / 1_000_000_000.0
  h['disktype'] = (node['storage_devices'].first[1] || {})['interface']

  # ETH
  ni_mountable = node['network_adapters'].select { |k, na| /^eth[0-9]*$/.match(k) && (na['enabled'] == true || na['mounted'] == true || na['mountable'] == true) }.values
  ni_fastest   = ni_mountable.max_by { |na| na['rate'] }

  h['eth_count'] = ni_mountable.length
  h['eth_rate']  = ni_fastest['rate'] / 1_000_000_000

  puts "#{node_uid}: Warning - no rate info for the eth interface" if h['eth_count'] > 0 && h['eth_rate'] == 0

  # INFINIBAND
  ni_mountable = node['network_adapters'].select { |k, na| /^ib[0-9]*(\.[0-9]*)?$/.match(k) && (na['enabled'] == true || na['mounted'] == true || na['mountable'] == true) }.values
  ni_fastest   = ni_mountable.max_by { |na| na['rate'] }
  ib_map = { 0 => 'NO', 10 => 'SDR', 20 => 'DDR', 40 => 'QDR', 56 => 'FDR' }

  h['ib_count'] = ni_mountable.length
  h['ib_rate']  = ni_mountable.length > 0 ? ni_fastest['rate'] / 1_000_000_000 : 0
  h['ib'] = ib_map[h['ib_rate']]

  puts "#{node_uid}: Warning - no rate info for the ib interface" if h['ib_count'] > 0 && h['ib_rate'] == 0

  # MYRINET
  ni_mountable = node['network_adapters'].select { |k, na| /^myri[0-9]*$/.match(k) && (na['enabled'] == true || na['mounted'] == true || na['mountable'] == true) }.values
  ni_fastest   = ni_mountable.max_by { |na| na['rate'] }
  myri_map = { 0 => 'NO', 2 => 'Myrinet-2000', 10 => 'Myri-10G' }

  h['myri_count'] = ni_mountable.length
  h['myri_rate']  = ni_mountable.length > 0 ? ni_fastest['rate'] / 1_000_000_000 : 0
  h['myri'] = myri_map[h['myri_rate']]

  puts "#{node_uid}: Warning - no rate info for the myri interface" if h['myri_count'] > 0 && h['myri_rate'] == 0

  h['memcore'] = node['main_memory']['ram_size'] / node['architecture']['nb_cores']/MiB
  h['memcpu'] = node['main_memory']['ram_size'] / node['architecture']['nb_procs']/MiB
  h['memnode'] = node['main_memory']['ram_size'] / MiB

  if node.key?('gpu') && node['gpu']['gpu'] == true
    h['gpu'] = node['gpu']['gpu_model']
    h['gpu_count'] = node['gpu']['gpu_count']
  else
    h['gpu'] = false
    h['gpu_count'] = 0
  end

  h['mic'] = if node['mic']
               'YES'
             else
               'NO'
             end

  node['monitoring'] ||= {}
  h['wattmeter'] = case node['monitoring']['wattmeter']
                   when true then true
                   when false then false
                   when nil then false
                   else node['monitoring']['wattmeter'].upcase
                   end

  h['cluster_priority'] = (cluster['priority'] || Time.parse(cluster['created_at'].to_s).strftime('%Y%m')).to_i

  h['production'] = false # default
  h['production'] = node['supported_job_types']['queues'].include?('production') if node['supported_job_types'] && node['supported_job_types'].has_key?('queues')

  h['max_walltime'] = 0 # default
  h['max_walltime'] = node['supported_job_types']['max_walltime'] if node['supported_job_types'] && node['supported_job_types'].has_key?('max_walltime')

  h['maintenance'] = false # default
  h['maintenance'] = node['supported_job_types']['queues'].include?('testing') if node['supported_job_types'] && node['supported_job_types'].has_key?('queues')

  # Disk reservation
  h['disk_reservation_count'] = node['storage_devices'].select { |_k, v| v['reservation'] }.length

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

def get_ref_disk_properties_internal(site_uid, cluster_uid, node_uid, node)
  properties = {}
  node['storage_devices'].to_a.each_with_index do |v, index|
    _device_uid, device = v
    if index > 0 && device['reservation']
      key = [node_uid, index]
      h = {}
      node_address = [node_uid, site_uid, 'grid5000.fr'].join('.')
      h['cluster'] = cluster_uid
      h['host'] = node_address
      h['network_address'] = ''
      h['disk'] = index
      h['diskpath'] = device['by_path']
      h['cpuset'] = 0
      properties[key] = h
    end
  end
  properties
end

def get_oar_default_properties(site_uid, filename, options)
  oarnodes = get_oar_data(site_uid, filename, options)

  # Handle the two possible input format from oarnodes -Y:
  # given by a file, and from the OAR API
  if oarnodes.is_a?(Hash)
    oarnodes = oarnodes.map { |_k, v| v['type'] == 'default' ? [get_ids(v['host'])['node_uid'], v] : [nil, nil] }.to_h
    oarnodes.delete(nil)
  elsif oarnodes.is_a?(Array)
    oarnodes = oarnodes.select { |v| v['type'] == 'default' }.map { |v| [get_ids(v['host'])['node_uid'], v] }.to_h
  else
    raise 'Invalid input format for OAR properties'
  end
  return oarnodes
end

def get_oar_disk_properties(site_uid, filename, options)
  oarnodes = get_oar_data(site_uid, filename, options)

  # Handle the two possible input format from oarnodes -Y:
  # given by a file, and from the OAR API
  if oarnodes.is_a?(Hash)
    oarnodes = oarnodes.map { |_k, v|  v['type'] == 'disk' ? [[get_ids(v['host'])['node_uid'], v['disk']], v] : [nil, nil] }.to_h
    oarnodes.delete(nil)
  elsif oarnodes.is_a?(Array)
    oarnodes = oarnodes.select { |v| v['type'] == 'disk' }.map { |v| [[get_ids(v['host'])['node_uid'], v['disk']], v] }.to_h
  else
    raise 'Invalid input format for OAR properties'
  end
  return oarnodes
end

# Get all data from the OAR database
def get_oar_data(site_uid, filename, options)
  oarnodes = ''
  if filename && File.exist?(filename)
    # Read OAR properties from file
    puts "Reading OAR resources properties from file #{filename}" if options[:verbose]
    oarnodes = YAML.load(File.open(filename, 'rb') { |f| f.read })
  else
    api_uri = URI.parse('https://api.grid5000.fr/stable/sites/' + site_uid  + '/internal/oarapi/resources/details.json?limit=999999')

    # Download the OAR properties from the OAR API (through G5K API)
    puts "Downloading resources properties from #{api_uri} ..." if options[:verbose]
    http = Net::HTTP.new(api_uri.host, Net::HTTP.https_default_port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(api_uri.request_uri)

    # For outside g5k network access
    if options[:api][:user] && options[:api][:pwd]
      request.basic_auth(options[:api][:user], options[:api][:pwd])
    end

    response = http.request(request)
    raise "Failed to fetch resources properties from API: \n#{response.body}\n" unless response.code.to_i == 200
    puts '... done' if options[:verbose]

    oarnodes = JSON.parse(response.body)
    if filename
      puts "Saving OAR resources properties as #{filename}" if options[:verbose]
      File.write(filename, YAML.dump(oarnodes))
    end
  end

  # Adapt from the format of the OAR API
  oarnodes = oarnodes['items'] if oarnodes.key?('items')
  return oarnodes
end

# Return a list of properties as a hash: { property1 => String, property2 => Fixnum, ... }
# We detect the type of the property (Fixnum/String) by looking at the existing values
def get_property_keys(properties)
  properties_keys = {}
  properties.each do |_site_uid, site_properties|
    site_properties.each do |type, type_properties|
      properties_keys.merge!(get_property_keys_internal(type, type_properties))
    end
  end
  return properties_keys
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
    ignore_keys.each { |key| properties_oar.delete(key) }
    ignore_keys.each { |key| properties_ref.delete(key) }
  elsif type == 'disk'
    properties_oar.select! { |k, _v| %w(cluster host network_address disk diskpath cpuset).include?(k) }
    properties_ref.select! { |k, _v| %w(cluster host network_address disk diskpath cpuset).include?(k) }
  end

  # Ignore the 'state' property only if the node is not 'Dead' according to
  # the reference-repo.
  # Otherwise, we must enforce that the node state is also 'Dead' on the OAR server.
  # On the OAR server, the 'state' property can be modified by phoenix. We ignore that.
  if type == 'default' && properties_ref['state'] != 'Dead'
    properties_oar.delete('state')
    properties_ref.delete('state')
  elsif type == 'default' && properties_ref.size == 1
    # For dead nodes, when information is missing from the reference-repo, only enforce the 'state' property and ignore other differences.
    return HashDiff.diff('state' => properties_oar['state'], 'state' => properties_ref['state'])
  end

  return HashDiff.diff(properties_oar, properties_ref)
end

# These keys will not be created neither compared with the -d option
# ignore_keys is only applied to resources of type 'default'
def ignore_keys()
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
  ignore_keys = [
    "chassis",
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
    "core",
    "cpu",
    "cpuset",
    "desktop_computing",
    "drain",
    "expiry_date",
    "finaud_decision",
    "grub",
    "host", # TODO
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
    "switch",
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
    "disk",
    "diskpath"
  ]
  return ignore_keys
end

def oarcmd_script_header()
  return <<EOF
#! /usr/bin/env bash

set -eu
set -o pipefail

EOF
end

def oarcmd_create_node_header()
  return <<EOF
node_exist () {
  [[ $(oarnodes --sql "host='$1' and type='default'") ]]
}

disk_exist () {
  [[ $(oarnodes --sql "host='$1' and type='disk' and disk=$2") ]]
}

EOF
end

def oarcmd_separator
  return "echo '" + '=' * 80 + "'\n\n"
end

def oarcmd_create_properties(properties_keys)
  command = ''
  properties_keys.each do |key, key_type|
    if key_type == Fixnum
      command += "oarproperty -a #{key} || true\n"
    elsif key_type == String
      command += "oarproperty -a #{key} --varchar || true\n"
    else
      raise "Error: the type of the '#{key}' property is unknown (Integer/String). Cannot generate the corresponding 'oarproperty' command. You must create this property manually ('oarproperty -a #{key} [--varchar]')"
    end
  end
  return command
end

def oarcmd_create_node(host, default_properties, node_hash)
  id = get_ids(host)
  node_exist = "node_exist '#{host}'"
  command  = "echo; echo 'Adding host #{host}:'\n"
  command += "#{node_exist} && echo '=> host already exists'\n"
  command += "#{node_exist} || oar_resources_add -a --hosts 1 --host0 #{id['node_num']} --host-prefix #{id['cluster_uid']}- --host-suffix .#{id['site_uid']}.#{id['grid_uid']}.fr --cpus #{node_hash['architecture']['nb_procs']} --cores #{default_properties['cpucore']}"
  command += ' | bash'
  return command + "\n\n"
end

def oarcmd_set_node_properties(host, default_properties)
  return '' if default_properties.size == 0
  command  = "echo; echo 'Setting properties for #{host}:'; echo\n"
  command += "oarnodesetting --sql \"host='#{host}' and type='default'\" -p "
  command +=
    default_properties.to_a.map{ |(k,v)|
    v = "YES" if v == true
    v = "NO"  if v == false
    ! v.nil? ? "#{k}=#{v.inspect.gsub("'", "\\'").gsub("\"", "'")}" : nil
  }.compact.join(' -p ')
  return command + "\n\n"
end

def oarcmd_create_disk(host, disk)
  disk_exist = "disk_exist '#{host}' '#{disk}'"
  command = "echo; echo 'Adding disk #{disk} on host #{host}:'\n"
  command += "#{disk_exist} && echo '=> disk already exists'\n"
  command += "#{disk_exist} || oarnodesetting -a -h '' -p host='#{host}' -p network_address='' -p type='disk' -p disk=#{disk}"
  return command + "\n\n"
end

def oarcmd_set_disk_properties(host, disk, disk_properties)
  return '' if disk_properties.size == 0
  command = "echo; echo 'Setting properties for disk #{disk} on host #{host}:'; echo\n"
  command += "oarnodesetting --sql \"host='#{host}' and type='disk' and disk=#{disk}\" -p "
  command +=
    disk_properties.to_a.map{ |(k,v)|
    v = "YES" if v == true
    v = "NO"  if v == false
    ! v.nil? ? "#{k}=#{v.inspect.gsub("'", "\\'").gsub("\"", "'")}" : nil
  }.compact.join(' -p ')
  command += "\n\n"
  return command
end

# sudo exec
def ssh_exec(site_uid, cmds, options)
  # The following is equivalent to : "cat cmds | bash"
  #res = ""
  c = Net::SSH.start(options[:ssh][:host].gsub("%s", site_uid), options[:ssh][:user], options[:ssh][:params])
  c.open_channel { |channel|
    channel.exec('sudo bash') { |ch, success|
      # stdout
      channel.on_data { |ch, data|
        puts data #if options[:verbose] # ssh cmd output
      }
      # stderr
      channel.on_extended_data do |ch, type, data|
        puts data
      end

      cmds.each { |cmd|
        channel.send_data cmd 
      }
      channel.eof!
    }
  }
  c.loop
end
