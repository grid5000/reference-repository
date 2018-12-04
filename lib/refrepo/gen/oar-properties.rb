# coding: utf-8

require 'hashdiff'
require 'refrepo/data_loader'
require 'net/ssh'

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
        puts "Error (missing property) while processing node #{node_uid}: #{e}"
      rescue Exception => e
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

  # ETH
  ni_mountable = node['network_adapters'].select { |na| /^eth[0-9]*$/.match(na['device']) && (na['enabled'] == true && (na['mounted'] == true || na['mountable'] == true)) }
  ni_fastest   = ni_mountable.max_by { |na| na['rate'] || 0 }

  h['eth_count'] = ni_mountable.length
  h['eth_rate']  = ni_fastest['rate'] / 1_000_000_000

  puts "#{node_uid}: Warning - no rate info for the eth interface" if h['eth_count'] > 0 && h['eth_rate'] == 0

  # INFINIBAND
  ni_mountable = node['network_adapters'].select { |na| /^ib[0-9]*(\.[0-9]*)?$/.match(na['device']) && (na['interface'] == 'InfiniBand' and na['enabled'] == true && (na['mounted'] == true || na['mountable'] == true)) }
  ni_fastest   = ni_mountable.max_by { |na| na['rate'] || 0 }
  ib_map = { 0 => 'NO', 10 => 'SDR', 20 => 'DDR', 40 => 'QDR', 56 => 'FDR' }

  h['ib_count'] = ni_mountable.length
  h['ib_rate']  = ni_mountable.length > 0 ? ni_fastest['rate'] / 1_000_000_000 : 0
  h['ib'] = ib_map[h['ib_rate']]

  puts "#{node_uid}: Warning - no rate info for the ib interface" if h['ib_count'] > 0 && h['ib_rate'] == 0
  
  # OMNIPATH
  ni_mountable = node['network_adapters'].select { |na| /^ib[0-9]*(\.[0-9]*)?$/.match(na['device']) && (na['interface'] == 'Omni-Path' and na['enabled'] == true && (na['mounted'] == true || na['mountable'] == true)) }
  ni_fastest   = ni_mountable.max_by { |na| na['rate'] || 0 }

  h['opa_count'] = ni_mountable.length
  h['opa_rate']  = ni_mountable.length > 0 ? ni_fastest['rate'] / 1_000_000_000 : 0
  h['opa'] = h['opa_count'] > 0

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
def get_ref_disk_properties_internal(site_uid, cluster_uid, node_uid, node)
  properties = {}
  node['storage_devices'].each_with_index do |device, index|
    disk = [device['device'], node_uid].join('.')
    if index > 0 && device['reservation'] # index > 0 is used to exclude sda
      key = [node_uid, disk]
      h = {}
      node_address = [node_uid, site_uid, 'grid5000.fr'].join('.')
      h['cluster'] = cluster_uid
      h['host'] = node_address
      h['network_address'] = ''
      h['available_upto'] = 0
      h['deploy'] = 'YES'
      h['production'] = get_production_property(node)
      h['maintenance'] = get_maintenance_property(node)
      h['disk'] = disk
      h['diskpath'] = device['by_path']
      h['cpuset'] = -1
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
  properties.each do |type, type_properties|
    properties_keys.merge!(get_property_keys_internal(type, type_properties))
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
    check_keys = %w(cluster host network_address available_upto deploy production maintenance disk diskpath cpuset)
    properties_oar.select! { |k, _v| check_keys.include?(k) }
    properties_ref.select! { |k, _v| check_keys.include?(k) }
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
    return HashDiff.diff({'state' => properties_oar['state']}, {'state' => properties_ref['state']})
  end

  return HashDiff.diff(properties_oar, properties_ref)
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
    "subnet_address",
    "subnet_prefix",
    "suspended_jobs",
    "thread",
    "type", # TODO
    "vlan",
    "pdu",
    "id", # id from API (= resource_id from oarnodes)
    "api_timestamp", # from API
    "links" # from API
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

def oarcmd_script_header()
  return <<EOF
#! /usr/bin/env bash

set -eu
set -o pipefail

EOF
end

def oarcmd_create_helper_functions()
  return <<EOF
property_exist () {
  [[ $(oarproperty -l | grep -e "^$1$") ]]
}

node_exist () {
  [[ $(oarnodes --sql "host='$1' and type='default'") ]]
}

disk_exist () {
  [[ $(oarnodes --sql "host='$1' and type='disk' and disk='$2'") ]]
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
      command += "property_exist '#{key}' || oarproperty -a #{key}\n"
    elsif key_type == String
      command += "property_exist '#{key}' || oarproperty -a #{key} --varchar\n"
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
  command += properties_internal(default_properties)
  return command + "\n\n"
end

def properties_internal(properties)
  str = properties.to_a.map do |(k, v)|
    v = "YES" if v == true
    v = "NO"  if v == false
    !v.nil? ? "#{k}=#{v.inspect.gsub("'", "\\'").gsub("\"", "'")}" : nil
  end.compact.join(' -p ')
  return str
end

def oarcmd_create_disk(host, disk)
  disk_exist = "disk_exist '#{host}' '#{disk}'"
  command = "echo; echo 'Adding disk #{disk} on host #{host}:'\n"
  command += "#{disk_exist} && echo '=> disk already exists'\n"
  command += "#{disk_exist} || oarnodesetting -a -h '' -p host='#{host}' -p network_address='' -p type='disk' -p disk='#{disk}'"
  return command + "\n\n"
end

def oarcmd_set_disk_properties(host, disk, disk_properties)
  return '' if disk_properties.size == 0
  command = "echo; echo 'Setting properties for disk #{disk} on host #{host}:'; echo\n"
  command += "oarnodesetting --sql \"host='#{host}' and type='disk' and disk='#{disk}'\" -p "
  command += properties_internal(disk_properties)
  return command + "\n\n"
end

# sudo exec
def ssh_exec(site_uid, cmds, options)
  # The following is equivalent to : "cat cmds | bash"
  #res = ""
  c = Net::SSH.start("oar.#{site_uid}.g5kadmin", "g5kadmin")
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

# Get the properties of each node
def get_oar_properties_from_the_ref_repo(global_hash, options)
  properties = {}
  sites = options[:sites]
  sites.each do |site_uid|
    properties[site_uid] = {}
    properties[site_uid]['default'] = get_ref_default_properties(site_uid, global_hash['sites'][site_uid])
    properties[site_uid]['disk'] = get_ref_disk_properties(site_uid, global_hash['sites'][site_uid])
  end
  return properties
end

def get_oar_properties_from_oar(options)
  properties = {}
  sites = options[:sites]
  diff = options[:diff]
  sites.each do |site_uid|
    filename = diff.is_a?(String) ? diff.gsub('%s', site_uid) : nil
    properties[site_uid] = {}
    properties[site_uid]['default'] = get_oar_default_properties(site_uid, filename, options)
    properties[site_uid]['disk'] = get_oar_disk_properties(site_uid, filename, options)
  end
  return properties
end

# Main program
# properties['ref'] = properties from the reference-repo
# properties['oar'] = properties from the OAR server
# properties['diff'] = diff between "ref" and "oar"

def generate_oar_properties(options)
  options[:api] = {}
  conf = RefRepo::Utils.get_api_config
  options[:api][:user] = conf['username']
  options[:api][:pwd] = conf['password']
  options[:ssh] = {}
  options[:ssh][:user] = 'g5kadmin'
  options[:ssh][:host] = 'oar.%s.g5kadmin'
  ret = true
  global_hash = load_data_hierarchy

  properties = {}
  properties['ref'] = get_oar_properties_from_the_ref_repo(global_hash, options)
  properties['oar'] = get_oar_properties_from_oar(options)

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
      puts "*** Error: The following nodes exist in the OAR server but are missing in the reference-repo: #{missings_alive.join(', ')}.\n"
      ret = false unless options[:exec] || options[:output]
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

          # Verbose output
          info = type == 'default' ? ' new node !' : ' new disk !' if properties['oar'][site_uid][type][key].nil?
          case options[:verbose]
          when 1
            puts "#{key}:#{info}" if info != ''
            puts "#{key}:#{diff_keys}" if diff.size != 0
          when 2
            # Give more details
            if header == false
              puts "Output format: ['~', 'key', 'old value', 'new value']"
              header = true
            end
            if diff.empty?
              puts "  #{key}: OK#{info}"
            elsif diff == prev_diff
              puts "  #{key}:#{info} same modifications as above"
            else
              puts "  #{key}:#{info}"
              diff.each { |d| puts "    #{d}" }
            end
            prev_diff = diff
          when 3
            # Even more details
            puts "#{key}:#{info}" if info != ''
            puts JSON.pretty_generate(key => { 'old values' => properties_oar, 'new values' => properties_ref })
          end
          if diff.size != 0
            ret = false unless options[:exec] || options[:output]
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
          # Detect inconsistency between the type (String/Fixnum) of properties generated by this script and the existing values on the server.
          puts "Error: the OAR property '#{k}' is a '#{v_oar}' on the #{site_uid} server and this script uses '#{v_ref}' for this property."
          ret = false unless options[:exec] || options[:output]
        end
      end

      puts "Properties that need to be created on the #{site_uid} server: #{properties_keys['diff'][site_uid].keys.to_a.delete_if { |e| ignore_default_keys.include?(e) }.join(', ')}" if options[:verbose] && properties_keys['diff'][site_uid].keys.to_a.delete_if { |e| ignore_default_keys.include?(e) }.size > 0

      # Detect unknown properties
      unknown_properties = properties_keys['oar'][site_uid].keys.to_set - properties_keys['ref'][site_uid].keys.to_set
      ignore_default_keys.each do |key|
        unknown_properties.delete(key)
      end

      if options[:verbose] && unknown_properties.size > 0
        puts "Properties existing on the #{site_uid} server but not managed/known by the generator: #{unknown_properties.to_a.join(', ')}."
        puts "Hint: you can delete properties with 'oarproperty -d <property>' or add them to the ignore list in lib/lib-oar-properties.rb."
        ret = false unless options[:exec] || options[:output]
      end
      puts "Skipped retired nodes: #{skipped_nodes}" if skipped_nodes.any?
    end # if options[:diff]
  end

  # Build and execute commands
  if options[:output] || options[:exec]
    skipped_nodes = [] unless options[:diff]
    opt = options[:diff] ? 'diff' : 'ref'

    properties[opt].each do |site_uid, site_properties|
      options[:output].is_a?(String) ? o = File.open(options[:output].gsub('%s', site_uid), 'w') : o = $stdout.dup

      ssh_cmd = []
      cmd = []
      cmd << oarcmd_script_header
      cmd << oarcmd_separator

      # Create helper functions
      cmd << oarcmd_create_helper_functions
      cmd << oarcmd_separator

      # Create properties keys
      properties_keys[opt][site_uid].delete_if { |k, _v| ignore_default_keys.include?(k) }
      unless properties_keys[opt][site_uid].empty?
        cmd << oarcmd_create_properties(properties_keys[opt][site_uid]) + "\n"
        cmd << oarcmd_separator
      end

      # Build and output node commands
      site_properties['default'].each_filtered_node_uid(options[:clusters], options[:nodes]) do |node_uid, node_properties|
        cluster_uid = node_uid.split('-')[0]
        node_address = [node_uid, site_uid, 'grid5000.fr'].join('.')

        if node_properties['state'] == 'Dead'
          # Do not log node skipping twice if we just did a diff
          skipped_nodes << node_uid unless options[:diff]
          next
        end

        # Create new nodes
        if opt == 'ref' || properties['oar'][site_uid]['default'][node_uid].nil?
          node_hash = global_hash['sites'][site_uid]['clusters'][cluster_uid]['nodes'][node_uid]
          cmd << oarcmd_create_node(node_address, node_properties, node_hash)
        end

        # Update properties
        unless node_properties.empty?
          cmd << oarcmd_set_node_properties(node_address, node_properties)
          cmd << oarcmd_separator
        end
        ssh_cmd += cmd if options[:exec]
        o.write(cmd.join('')) if options[:output]
        cmd = []
      end

      # Build and output disk commands
      site_properties['disk'].each_filtered_node_uid(options[:clusters], options[:nodes]) do |key, disk_properties|
        # As an example, key can be equal to 'grimoire-1' for default resources or
        # ['grimoire-1', 'sdb.grimoire-1'] for disk resources (disk sdb of grimoire-1)
        node_uid, disk = key
        host = [node_uid, site_uid, 'grid5000.fr'].join('.')

        next if skipped_nodes.include?(node_uid)

        # Create a new disk
        if opt == 'ref' || properties['oar'][site_uid]['disk'][key].nil?
          cmd << oarcmd_create_disk(host, disk)
        end

        # Update the disk properties
        unless disk_properties.empty?
          cmd << oarcmd_set_disk_properties(host, disk, disk_properties)
          cmd << oarcmd_separator
        end

        ssh_cmd += cmd if options[:exec]
        o.write(cmd.join('')) if options[:output]
        cmd = []
      end
      o.close

      # Execute commands
      if options[:exec]
        printf 'Apply changes to the OAR server ' + options[:ssh][:host].gsub('%s', site_uid) + ' ? (y/N) '
        prompt = STDIN.gets.chomp
        ssh_exec(site_uid, ssh_cmd, options) if prompt.downcase == 'y'
      end
    end # site loop

    if skipped_nodes.any?
      puts "Skipped retired nodes: #{skipped_nodes}" unless options[:diff]
    end
  end # if options[:output] || options[:exec]

  return ret
end
