#!/usr/bin/ruby

require 'pp'
require 'erb'
require 'fileutils'
require 'pathname'
require 'json'
require 'time'
require 'yaml'
require 'hashdiff'
require 'set'

class MissingProperty <  StandardError; end

MiB = 1024**2

# Get node properties from the reference repo hash
# See also: https://www.grid5000.fr/mediawiki/index.php/Reference_Repository
def get_node_properties(cluster_uid, cluster, node_uid, node)
  h = {} # ouput

  if node['status'] == 'retired'
    h['state'] = 'Dead'
    return h if node.size == 1 # for dead nodes, additional information is most likely missing from the ref-repository.
  end

  main_network_adapter = node['network_adapters'].find{|k, na| /^eth[0-9]*$/.match(k) && na['enabled'] && na['mounted'] && !na['management'] }
  raise MissingProperty, "Node #{node_uid} does not have a main network_adapter" unless main_network_adapter

  #  h['host']            = main_network_adapter['network_address']
  #TODO  raise MissingProperty, "Node #{node_uid} has no network_address" unless h['host']

  h['ip']              = main_network_adapter['ip']
  raise MissingProperty, "Node #{node_uid} has no IP" unless h['ip']
  h['cluster']         = cluster_uid
  h['nodemodel']       = cluster['model']
  h['switch']          = main_network_adapter['switch']
  h['besteffort']      = node['supported_job_types']['besteffort']
  h['deploy']          = node['supported_job_types']['deploy']
  h['ip_virtual']      = node['supported_job_types']['virtual'] == 'ivt'
  h['virtual']         = node['supported_job_types']['virtual']
  h['cpuarch']         = node['architecture']['platform_type']
  h['cpucore']         = node['architecture']['smt_size']/node['architecture']['smp_size']
  h['cputype']         = [node['processor']['model'], node['processor']['version']].join(' ')
  h['cpufreq']         = node['processor']['clock_speed']/1_000_000_000.0
  h['disktype']        = (node['storage_devices'].first[1] || {})['interface']

  # ETH
  ni_mountable = node['network_adapters'].select{|k, na| /^eth[0-9]*$/.match(k) && (na['enabled'] == true || na['mounted'] == true || na['mountable'] == true)}.values
  ni_fastest   = ni_mountable.max_by{|na| na['rate']}
  
  h['eth_count'] = ni_mountable.length
  h['eth_rate']  = ni_fastest['rate'] / 1_000_000_000
  
  puts "#{node_uid}: Warning - no rate info for the eth interface" if h['eth_count'] > 0 && h['eth_rate'] == 0

  # INFINIBAND
  ni_mountable = node['network_adapters'].select{|k, na| /^ib[0-9]*$/.match(k) && (na['enabled'] == true || na['mounted'] == true || na['mountable'] == true)}.values
  ni_fastest   = ni_mountable.max_by{|na| na['rate']}
  ib_map = {0 => 'NO', 10 => 'SDR', 20 => 'DDR', 40 => 'QDR', 56 => 'FDR'}

  h['ib_count'] = ni_mountable.length
  h['ib_rate']  = ni_mountable.length > 0 ? ni_fastest['rate'] / 1_000_000_000 : 0
  h['ib']  = ib_map[h['ib_rate']]

  puts "#{node_uid}: Warning - no rate info for the ib interface" if h['ib_count'] > 0 && h['ib_rate'] == 0

  # MYRINET
  ni_mountable = node['network_adapters'].select{|k, na| /^myri[0-9]*$/.match(k) && (na['enabled'] == true || na['mounted'] == true || na['mountable'] == true)}.values
  ni_fastest   = ni_mountable.max_by{|na| na['rate']}
  myri_map = {0 => 'NO', 2 => 'Myrinet-2000', 10 => 'Myri-10G'}

  h['myri_count'] = ni_mountable.length
  h['myri_rate']  = ni_mountable.length > 0 ? ni_fastest['rate'] / 1_000_000_000 : 0
  h['myri']  = myri_map[h['myri_rate']]

  puts "#{node_uid}: Warning - no rate info for the myri interface" if h['myri_count'] > 0 && h['myri_rate'] == 0

  #
  h['memcore']         = node['main_memory']['ram_size']/node['architecture']['smt_size']/MiB
  h['memcpu']          = node['main_memory']['ram_size']/node['architecture']['smp_size']/MiB
  h['memnode']         = node['main_memory']['ram_size']/MiB

  node['gpu']  ||= {}
  h['gpu']             = case node['gpu']['gpu'] when true; true; when false; false when nil; false; else node['gpu']['gpu'].upcase end
  h['gpu_count']       = node['gpu']['gpu_count']
  h['gpu_model']       = node['gpu']['gpu_model']

  node['monitoring'] ||= {}

  h['wattmeter'] = case node['monitoring']['wattmeter'] when true; true; when false; false when nil; false; else node['monitoring']['wattmeter'].upcase end

  # h['rconsole'] = node['monitoring']['rconsole']

  h['cluster_priority'] = (cluster['priority'] || Time.parse(cluster['created_at'].to_s).strftime('%Y%m')).to_i
  
  h['production'] = false # default
  h['production'] = node['supported_job_types']['queues'].include?('production') if node['supported_job_types'] && node['supported_job_types'].has_key?('queues')

  h['max_walltime'] = 0 # default
  h['max_walltime'] = node['supported_job_types']['max_walltime'] if node['supported_job_types'] && node['supported_job_types'].has_key?('max_walltime')
  
  # convert booleans to YES/NO string
  h.each {|k,v|
    if v == true
      h[k] = 'YES'
    elsif v == false
      h[k] = 'NO'
    elsif v.is_a? Float
      h[k] = "#{v}"
    end
  }

  return h
end

#
#
#
def get_nodelist_properties(site_uid, site)
  properties = {} # output
  
  site['clusters'].each do |cluster_uid, cluster|

    cluster['nodes'].each do |node_uid, node|

      begin
        properties[node_uid] = get_node_properties(cluster_uid, cluster, node_uid, node)
      rescue MissingProperty => e
        puts "Error while processing node #{node_uid}: #{e}"
      end

    end
  end

  return properties
end

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
                 "maintenance",
                 "mic", # TODO
                 "network_address", # TODO
                 "next_finaud_decision",
                 "next_state",
                 "rconsole", # TODO
                 "resource_id",
                 "scheduler_priority",
                 "state_num",
                 "switch", # TODO
                 "subnet_address",
                 "subnet_prefix",
                 "suspended_jobs",
                 "thread",
                 "type", # TODO
                 "vlan",
                 "pdu",
                 "wattmeter" # TODO
                ]

end

def diff_node_properties(node_properties_oar, node_properties_ref)
  node_properties_oar ||= {}
  node_properties_ref ||= {}

  ignore_keys.each { |key| node_properties_oar.delete(key) }
  ignore_keys.each { |key| node_properties_ref.delete(key) }

  # Ignore the 'state' property only if the node is not 'Dead' according to the reference-repo.
  # Otherwise, we must enforce that the node state is also 'Dead' on the OAR server.
  # On the OAR server, the 'state' property can be modified by phoenix. We ignore that.
  if node_properties_ref['state'] != 'Dead'
    node_properties_oar.delete('state')
    node_properties_ref.delete('state')
  elsif node_properties_ref.size == 1
    # For dead nodes, when information is missing from the reference-repo, only enforce the 'state' property and ignore other differences.
    return HashDiff.diff({'state' => node_properties_oar['state']}, {'state' => node_properties_ref['state']})
  end

  return HashDiff.diff(node_properties_oar, node_properties_ref)

end

# Return a list of properties (as a hash: { property1 => String, property2 => Fixnum, ... })
# We try to detect the type of the property (Fixnum/String) by looking at the existing values. This is not possible if no value is set (NilClass).
def get_property_keys(nodelist_properties)
  properties_keys = {}
  nodelist_properties.each { |site_uid, site_properties| 
    # We do not use site/cluster/node filters here as we want the same list of properties across OAR servers
    site_properties.each { |node_uid, node_properties| 
      next if node_uid == nil
      
      node_properties.each { |k, v|
        unless properties_keys.key?(k) && NilClass === v
          properties_keys[k] = v.class
        end
      }
    }
  }
  return properties_keys
end

def oarcmd_script_header()
  return <<EOF
set -eu

EOF
end

def oarcmd_create_node_header()
  return <<EOF
nodelist=$(oarnodes -l)

list_contains () { 
    [[ "$1" =~ (^|[[:space:]])"$2"($|[[:space:]]) ]] && return 0 || return 1
}

EOF

end

def oarcmd_create_node(host, properties, node_hash) # host = grifffon-1.nancy.grid5000.fr; properties, node_hash: input of the reference API for the node
  #return "# Cannot create #{host} : not enough information about it (node_hash['architecture']['smp_size'], properties['cpucore'])" if node_hash['architecture'].nil? || properties['cpucore'].nil?

  node_uid, site_uid, grid_uid = host.split(".")
  cluster_uid, node_number     = node_uid.split("-")

  command  = "echo; echo 'Adding host #{host}:'\n"
  command += 'list_contains "$nodelist" "' + host + '" && '
  command += "echo '=> host already exist'\n"
  command += 'list_contains "$nodelist" "' + host + '" || '
  command += "oar_resources_add -a --hosts 1 --host0 #{node_number} --host-prefix #{cluster_uid}- --host-suffix .#{site_uid}.#{grid_uid}.fr --cpus #{node_hash['architecture']['smp_size']} --cores #{properties['cpucore']}"
  command += ' | bash'
  
  return command + "\n"
end

def oarcmd_set_node_properties(host, properties)
  #return "# #{host}: OK" if properties.size == 0
  return "" if properties.size == 0

  command  = "echo; echo 'Setting properties for #{host}:'; echo\n"
  command += "oarnodesetting -h #{host} -p "

  command +=
    properties.to_a.map{ |(k,v)|
    v = "YES" if v == true
    v = "NO"  if v == false
    
    ! v.nil? ? "#{k}=#{v.inspect.gsub("'", "\\'").gsub("\"", "'")}" : nil
  }.compact.join(' -p ')
  
  return command + "\n"
end
# '

# Get the OAR properties from the OAR scheduler
# This is only needed for the -d option
def oarcmd_get_nodelist_properties(site_uid, filename=nil, options)
  oarnodes_yaml = ""
  
  if filename and File.exist?(filename)
    # Read oar properties from file
    puts "Read 'oarnodes -Y' from #{filename}" if options[:verbose]
    oarnodes_yaml = File.open(filename, 'rb') { |f| f.read }
  else
    # Download the oar properties from the oar server
    puts "Downloading 'oarnodes -Y' from " + options[:ssh][:host].gsub("%s", site_uid) + "..." if options[:verbose]

    Net::SSH.start(options[:ssh][:host].gsub("%s", site_uid), options[:ssh][:user], options[:ssh][:params]) { |ssh|
      # capture all stderr and stdout output from a remote process
      oarnodes_yaml = ssh.exec!('oarnodes -Y')
    }
    puts "... done" if options[:verbose]

    if filename
      # Cache the file
      puts "Save 'oarnodes -Y' as #{filename}" if options[:verbose]
      File.write(filename, oarnodes_yaml)
    end
  end

  # Load the YAML file into an hashtable
  h = YAML.load(oarnodes_yaml)

  # Format convertion: use host as keys of the hash (instead of id)
  h = h.map {|k, v| v['type'] == 'default' ? [v['host'].split('.').first, v] : [nil, nil] }.to_h

  return h
end

def oarcmd_create_properties(properties_keys)
  command = ""
  properties_keys.each { |key, type|
    if type == Fixnum
      command += "oarproperty -a #{key} || true\n"
    elsif type == String
      command += "oarproperty -a #{key} --varchar || true\n"
    else
      raise "Error: the type of the '#{key}' property is unknown (Integer/String). Cannot generate the corresponding 'oarproperty' command. You must create this property manually ('oarproperty -a #{key} [--varchar]')"
    end
  }
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
