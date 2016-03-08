#!/usr/bin/ruby

require 'pp'
require 'erb'
require 'fileutils'
require 'pathname'
require 'json'
require 'time'
require 'yaml'
require 'hashdiff'

class MissingProperty <  StandardError; end

MiB = 1024**2

# Get node properties from the reference repo hash
def get_node_properties(cluster_uid, cluster, node_uid, node)
  h = {} # ouput

  main_network_adapter = node['network_interfaces'].values.find{ |na| na['enabled'] && na['mounted'] && na['interface'] =~ /ethernet/i && !na['management'] }
  main_network_adapter = node['network_interfaces'].values.find{ |na| na['enabled'] && na['mounted'] }
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
  h['disktype']        = (node['block_devices'].first[1] || {})['interface']
  h['ethnb']           = node['network_interfaces'].values.select{|na| na['interface'] =~ /ethernet/i}.select{|nb| nb['mountable'] == true}.length

  eth10g               = node['network_interfaces'].values.select{|na| na['interface'] =~ /ethernet/i}.select{|nb| nb['mountable'] == true}
  h['eth10g']          = eth10g.detect{|na| na['rate'] == 10_000_000_000}.nil? ? false : true

  ib10g                = node['network_interfaces'].values.detect{|na| na['interface'] =~ /infiniband/i && na['rate'] == 10_000_000_000}
  h['ib10g']           = ib10g ? true : false
  h['ib10gmodel']      = ib10g ? ib10g['version'] : 'none'

  ib20g                = node['network_interfaces'].values.detect{|na| na['interface'] =~ /infiniband/i && na['rate'] == 20_000_000_000}
  h['ib20g']           = ib20g ? true : false
  h['ib20gmodel']      = ib20g ? ib20g['version'] : 'none'

  ib40g                = node['network_interfaces'].values.detect{|na| na['interface'] =~ /infiniband/i && na['rate'] == 40_000_000_000}
  h['ib40g']           = ib40g ? true : false
  h['ib40gmodel']      = ib40g ? ib40g['version'] : 'none'

  ib56g                = node['network_interfaces'].values.detect{|na| na['interface'] =~ /infiniband/i && na['rate'] == 56_000_000_000}
  h['ib56g']           = ib56g ? true : false
  h['ib56gmodel']      = ib56g ? ib56g['version'] : 'none'

  myri10g              = node['network_interfaces'].values.detect{|na| na['interface'] =~ /myri/i && na['rate'] == 10_000_000_000}
  h['myri10g']         = myri10g ? true : false
  h['myri10gmodel']    = myri10g ? myri10g['version'] : 'none'

  myri2g               = node['network_interfaces'].values.detect{|na| na['interface'] =~ /myri/i && na['rate'] == 2_000_000_000}
  h['myri2g']          = myri2g ? true : false
  h['myri2gmodel']     = myri2g ? myri2g['version'] : 'none'

  h['memcore']         = node['main_memory']['ram_size']/node['architecture']['smt_size']/MiB
  h['memcpu']          = node['main_memory']['ram_size']/node['architecture']['smp_size']/MiB
  h['memnode']         = node['main_memory']['ram_size']/MiB

  node['gpu']  ||= {}
  h['gpu']             = case node['gpu']['gpu'] when true; true; when false; false when nil; false; else node['gpu']['gpu'].upcase end
  h['gpu_count']       = node['gpu']['gpu_count']
  h['gpu_model']       = node['gpu']['gpu_model']

  node['monitoring'] ||= {}

  h['wattmeter'] = case node['monitoring']['wattmeter'] when true; 'YES'; when false; 'NO' when nil; 'NO'; else node['monitoring']['wattmeter'].upcase end

  # h['rconsole'] = node['monitoring']['rconsole']

  h['cluster_priority'] = (cluster['priority'] || Time.parse(cluster['created_at'].to_s).strftime('%Y%m')).to_i
  
  h['production'] = false # default
  h['production'] = node['supported_job_types']['queues'].include?('production') if node['supported_job_types'] && node['supported_job_types'].has_key?('queues')

  h['max_walltime'] = 0 # default
  h['max_walltime'] = node['supported_job_types']['max_walltime'] if node['supported_job_types'] && node['supported_job_types'].has_key?('max_walltime')
  
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
        # puts "Error while processing node #{node_uid}: #{e}"
      end

    end
  end

  return properties
end

def diff_node_properties(a, b)

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
                 "state",
                 "state_num",
                 "switch", # TODO
                 "subnet_address",
                 "subnet_prefix",
                 "suspended_jobs",
                 "thread",
                 "type", # TODO
                 "vlan",
                 "ib56g", # TODO
                 "ib56gmodel", # TODO
                 "wattmeter" # TODO
                ]
  
  ignore_keys.each { |key| a.delete(key) }
  ignore_keys.each { |key| b.delete(key) }

  return HashDiff.diff(a, b)

end

#def cmd_set_oarnodesetting(properties)
#  properties.each
#end

def oarcmd_set_node_properties(host, properties)
  #return "# #{host}: OK" if properties.size == 0
  return "" if properties.size == 0

  # command = "# #{host}:\n"
  # command += "#{ENV["SUDO"]} oarnodesetting -h #{host} -p "
  command = "oarnodesetting -h #{host} -p "

  command +=
    properties.to_a.map{ |(k,v)|
    v = "YES" if v == true
    v = "NO"  if v == false
    
    ! v.nil? ? "#{k}=#{v.inspect.gsub("'", "\\'").gsub("\"", "'")}" : nil
  }.compact.join(' -p ')
  
  return command
end
# '

# Get the OAR properties from the OAR scheduler
# This is only needed for the -d option
def oarcmd_get_nodelist_properties(site_uid, filename=nil, sshkeys=[])
  oarnodes_yaml = ""

  if filename and File.exist?(filename)
    # Read oar properties from file
    puts "Read 'oarnodes -Y' from #{filename}"
    oarnodes_yaml = File.open(filename, 'rb') { |f| f.read }
  else
    # Download the oar properties from the oar server
    puts "Downloading 'oarnodes -Y' from oar.#{site_uid}.g5kadmin ..."

    Net::SSH.start("oar.#{site_uid}.g5kadmin", 'g5kadmin', :keys => sshkeys) { |ssh|
      # capture all stderr and stdout output from a remote process
      oarnodes_yaml = ssh.exec!('oarnodes -Y')
    }
    puts "... done"

    if filename
      # Cache the file
      puts "Save 'oarnodes -Y' as #{filename}"
      File.write(filename, oarnodes_yaml)
    end
  end

  # Load the YAML file into an hashtable
  h = YAML.load(oarnodes_yaml)

  # Format convertion: use host as keys of the hash (instead of id)
  h = h.map {|k, v| v['type'] == 'default' ? [v['host'].split('.').first, v] : [nil, nil] }.to_h

  return h
end

