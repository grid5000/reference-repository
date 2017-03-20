#!/usr/bin/env ruby

# !!! Require to "gem install ruby-ip", do not install "ip" gem !!!


require 'json'
require 'fileutils'

if RUBY_VERSION < "2.1"
  puts "This script requires ruby >= 2.1"
  exit
end

require 'pp'
require 'yaml'
require 'pathname'
require 'optparse'
require_relative '../lib/input_loader'
require_relative '../lib/hash/hash.rb'

input_data_dir = "../../input/grid5000/"

options = {}
options[:sites] = %w{grenoble lille luxembourg lyon nancy nantes rennes sophia}
options[:output_dir] = "/tmp/puppet-repo"
options[:conf_dir] = "./conf-examples/"

OptionParser.new do |opts|
  opts.banner = "Usage: kavlang5k.rb [options]"

  opts.separator ""
  opts.separator "Example: ruby kavlang5k.rb -s nancy -o /tmp/puppet-repo"

  opts.on('-o', '--output-dir dir', String, 'Select the puppet repo path', "Default: " + options[:output_dir]) do |d|
    options[:output_dir] = d
    options[:conf_dir] = "#{options[:output_dir]}/modules/kavlang5k/generators/"
  end

  opts.on('-c', '--conf-dir dir', String, 'Select the kavlan module configuration path', "Default: ./conf-examples") do |d|
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

puts "Writing kavlan configuration files to: #{options[:output_dir]}"
puts "Using configuration directory: #{options[:conf_dir]}"
puts "For site(s): #{options[:sites].join(', ')}"

refapi      = load_yaml_file_hierarchy("../../input/grid5000/")

refapi['sites'].each { |site_uid, site_refapi|

  next unless options[:sites].include?(site_uid)

  conf = YAML::load(ERB.new(File.read("#{options[:conf_dir]}/kavlang5k.yaml"), nil, '-').result(binding))[site_uid]
  if not conf
    warn "No generator configuration for site #{site_uid} found in #{options[:conf_dir]}/kavlang5k.yaml, skipping kavlan.conf"
  else
    output = ERB.new(File.read('templates/kavlan.conf.erb'), nil, '-').result(binding)
    output_file = Pathname("#{options[:output_dir]}/modules/kavlang5k/files/#{site_uid}/kavlan.conf")
    output_file.dirname.mkpath()
    File.write(output_file, output)
  end

  output = ERB.new(File.read('templates/kavlan-cluster.conf.erb'), nil, '-').result(binding)
  output_file = Pathname("#{options[:output_dir]}/modules/kavlang5k/files/#{site_uid}/#{site_uid}.conf")
  output_file.dirname.mkpath()
  File.write(output_file, output)

  (1..9).each do |kavlan_id|
    output = ERB.new(File.read('templates/kavlan-dhcp.conf.erb'), nil, '-').result(binding)
    output_file = Pathname("#{options[:output_dir]}/modules/kavlang5k/files/#{site_uid}/dhcp/dhcpd-#{kavlan_id}.conf")
    output_file.dirname.mkpath()
    File.write(output_file, output)
  end

  # Look for site's global kavlan
  kavlan_id = refapi['sites'][site_uid]['kavlans'].each_key.select {|k| k.is_a?(Numeric) and k>9}.pop()
  output = ERB.new(File.read('templates/kavlan-dhcp.conf.erb'), nil, '-').result(binding)
  output_file = Pathname("#{options[:output_dir]}/modules/kavlang5k/files/#{site_uid}/dhcp/dhcpd-0.conf")
  File.write(output_file, output)

}
