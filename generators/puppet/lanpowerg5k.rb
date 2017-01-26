#!/usr/bin/ruby

if RUBY_VERSION < "2.1"
  puts "This script requires ruby >= 2.1"
  exit
end

# This script generates lanpowerg5k/files/<site_uid>/lanpower.conf from conf/console.yaml and conf/console-password.conf

require 'pp'
require 'yaml'
require 'pathname'
require 'optparse'
require '../lib/input_loader'
require '../lib/hash/hash.rb'

options = {}
options[:sites] = %w{grenoble lille luxembourg lyon nancy nantes rennes sophia}
options[:output_dir] = "/tmp/puppet-repo"
options[:conf_dir] = "./conf-examples/"

OptionParser.new do |opts|
  opts.banner = "Usage: lanpowerg5k.rb [options]"

  opts.separator ""
  opts.separator "Example: ruby lanpowerg5k.rb -s nancy -o /tmp/puppet-repo"

  opts.on('-o', '--output-dir dir', String, 'Select the puppet repo path', "Default: " + options[:output_dir]) do |d|
    options[:output_dir] = d
    options[:conf_dir] = "#{options[:output_dir]}/modules/lanpowerg5k/generators/"
  end

  opts.on('-c', '--conf-dir dir', String, 'Select the lanpower module configuration path', "Default: ./conf-examples") do |d|
    options[:conf_dir] = d
  end

  opts.separator ""
  opts.separator "Filters:"

  opts.on('-s', '--sites a,b,c', Array, 'Select site(s)', "Default: " + options[:sites].join(", ")) do |s|
    raise "Wrong argument for -s option." unless (s - options[:sites]).empty?
    options[:sites] = s
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

raise("Error: #{options[:conf_dir]} does not exist. The given configuration path is incorrect") unless Pathname(options[:conf_dir].to_s).exist?

puts "Writing lanpower configuration files to: #{options[:output_dir]}"
puts "Using configuration directory: #{options[:conf_dir]}"
puts "For site(s): #{options[:sites].join(', ')}"

config      = YAML::load_file("#{options[:conf_dir]}console.yaml")
credentials = YAML::load_file("#{options[:conf_dir]}console-password.yaml")
refapi      = load_yaml_file_hierarchy("../../input/grid5000/")

refapi['sites'].each { |site_uid, site_refapi|

  next unless options[:sites].include?(site_uid)

  h = {'clusters' => {} } # output hash

  # Generate config for both cluster and server entries of the refapi
  site_refapi['servers'] ||= {}
  cluster_list = site_refapi['clusters'].keys | site_refapi['servers'].keys | config[site_uid].keys | credentials[site_uid].keys

  cluster_list.sort.each { |cluster_uid| 
    cluster_refapi      = site_refapi['clusters'][cluster_uid].fetch('nodes') rescue site_refapi['servers'][cluster_uid].fetch('nodes') rescue nil
    cluster_config      = config[site_uid][cluster_uid]['lanpower'] rescue nil
    cluster_credentials = credentials[site_uid].fetch(cluster_uid) rescue nil

    # error handling:
    # - refapi is optional for this generator but every cluster should still be on the ref api => display a warning message
    # - credentials are mandatory and the cluster is skipped if info is missing
    # - config is optional as the cluster might use the default configuration
    puts "Warning: #{site_uid} - #{cluster_uid} not found in the reference api" if cluster_refapi.nil?
    if cluster_credentials.nil?
      puts "Warning: #{site_uid} - #{cluster_uid} not found in console-password.yaml... skipped"
      next
    end

    # clusters:
    #   griffon:
    #     bmc: "ipmi"
    #     user: ""
    #     password: ""
    #     suffix: "-bmc"
    #     sleep: "6"

    cluster_hash = {}
    cluster_hash['bmc']           = cluster_config.fetch('bmc') rescue 'ipmi'
    cluster_hash['user']          = cluster_credentials.split(' ')[0]
    cluster_hash['password']      = cluster_credentials.split(' ')[1]
    cluster_hash['sleep']         = cluster_config.fetch('sleep') rescue '6'
    cluster_hash['command_delay'] = cluster_config.fetch('command_delay') rescue nil

    cluster_hash['suffix']        = cluster_config.fetch('suffix') rescue nil
    cluster_hash['suffix']        = cluster_refapi["#{cluster_uid}-1"]['network_adapters']['bmc'].fetch('network_address').split('.')[0].gsub("#{cluster_uid}-1",'') rescue '-bmc' if cluster_hash['suffix'].nil?

    cluster_hash.reject!{ |k,v| v == nil } 

    h['clusters'][cluster_uid] = cluster_hash
    
  } # clusters.each

  # Write output file
  output_file = Pathname("#{options[:output_dir]}/modules/lanpowerg5k/files/#{site_uid}/lanpower.yaml")
  output_file.dirname.mkpath()
  write_yaml(output_file, h)
  add_header(output_file)

}
