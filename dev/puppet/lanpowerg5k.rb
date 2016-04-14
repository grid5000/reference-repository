#!/usr/bin/ruby

# This script generates lanpowerg5k/files/<site_uid>/lanpower.conf from conf/console.yaml and conf/console-password.conf

require 'pp'
require 'yaml'
require 'fileutils'
require '../lib/input_loader'
require '../lib/hash/hash.rb'

$output_dir = 'output'

password = YAML::load_file('conf/console-password.yaml')
console  = YAML::load_file('conf/console.yaml')

refapi   = load_yaml_file_hierarchy("../input/grid5000/")

refapi["sites"].each { |site_uid, site|

  h = {'clusters' => {} }
  
  site['clusters'].sort.each { |cluster_uid, cluster_refapi| 

    cluster_console  = console[site_uid][cluster_uid]['lanpower'] rescue nil
    cluster_password = password[site_uid].fetch(cluster_uid)

    #   clusters:
    #     griffon:
    #       bmc: "ipmi"
    #       user: ""
    #       password: ""
    #       suffix: "-bmc"
    #       sleep: "6"

    cluster_hash = {}
    cluster_hash['bmc']           = cluster_console.fetch('bmc') rescue 'ipmi'
    cluster_hash['user']          = cluster_password.split(' ')[0]
    cluster_hash['password']      = cluster_password.split(' ')[1]
    cluster_hash['sleep']         = cluster_console.fetch('sleep') rescue '6'
    cluster_hash['command_delay'] = cluster_console.fetch('command_delay') rescue nil

    cluster_hash['suffix']        = cluster_console.fetch('suffix') rescue nil
    cluster_hash['suffix']        = cluster_refapi['nodes']["#{cluster_uid}-1"]['network_adapters']['bmc'].fetch('network_address').split('.')[0].gsub("#{cluster_uid}-1",'') rescue '-bmc' unless cluster_hash['suffix']

    cluster_hash.reject!{ |k,v| v == nil } 

    h['clusters'][cluster_uid] = cluster_hash
    
  } # clusters.each
  
  # Write output file
  output_file = File.join($output_dir, 'lanpowerg5k', 'files', site_uid, 'lanpower.yaml')
  
  dirname = File.dirname(output_file)
  FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
  
  write_yaml(output_file, h)

}
