#!/usr/bin/ruby

if RUBY_VERSION < "2.1"
  puts "This script requires ruby >= 2.1"
  exit
end

# This script generates conmang5k/files/<site_uid>/conman.conf from input/, conf/console.yaml and conf/console-password.yaml

require 'pp'
require 'erb'
require 'pathname'
require 'optparse'
require '../lib/input_loader'
require '../lib/hash/hash.rb'

options = {}
options[:sites] = %w{grenoble lille luxembourg lyon nancy nantes rennes sophia}
options[:output_dir] = "/tmp/puppet-repo"
options[:conf_dir] = "./conf-examples/"

OptionParser.new do |opts|
  opts.banner = "Usage: conmang5k.rb [options]"

  opts.separator ""
  opts.separator "Example: ruby conmang5k.rb -s nancy -o /tmp/puppet-repo"

  opts.on('-o', '--output-dir dir', String, 'Select the puppet repo path', "Default: " + options[:output_dir]) do |d|
    options[:output_dir] = d
    options[:conf_dir] = "#{options[:output_dir]}/modules/lanpowerg5k/generators/"
  end

  opts.on('-c', '--conf-dir dir', String, 'Select the conman configuration path', "Default: ./conf-examples/") do |d|
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

puts "Writing Conman configuration files to: #{options[:output_dir]}"
puts "Using configuration directory: #{options[:conf_dir]}"
puts "For site(s): #{options[:sites].join(', ')}"

# Input
refapi      = load_yaml_file_hierarchy("../../input/grid5000/")
config      = YAML::load_file(options[:conf_dir] + 'console.yaml')
credentials = YAML::load_file(options[:conf_dir] + 'console-password.yaml')

# Apply ERB template and save result to file
def write_conman_file(site_uid, site_refapi, site_config, site_credentials, options)
  output = ERB.new(File.read("templates/conman.erb")).result(binding)

  output_file = Pathname("#{options[:output_dir]}/modules/conmang5k/files/#{site_uid}/conman.conf")
  output_file.dirname.mkpath()
  File.write(output_file, output)
end

# Loop over each site
refapi["sites"].each { |site_uid, site_refapi|

  next unless options[:sites].include?(site_uid)

  write_conman_file(site_uid, site_refapi, config[site_uid], credentials[site_uid], options)
}
