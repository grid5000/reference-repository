#!/usr/bin/ruby

if RUBY_VERSION < "2.1"
  puts "This script requires ruby >= 2.1"
  exit
end

# This script generates conmang5k/files/<site_uid>/conman.conf from input/, conf/console.yaml and conf/console-password.yaml

require 'pp'
require 'erb'
require 'pathname'
require '../lib/input_loader'
require '../lib/hash/hash.rb'

$output_dir = ENV['puppet_repo'] || '/tmp/puppet-repo'
$conf_dir   = ENV['conf_dir']    || Pathname("#{$output_dir}/modules/lanpowerg5k/generators/")
raise("Error: #{$conf_dir} does not exist. The environment variables are not set propertly") unless Pathname($conf_dir).exist?

# Input
refapi      = load_yaml_file_hierarchy("../../input/grid5000/")
config      = YAML::load_file($conf_dir + 'console.yaml')
credentials = YAML::load_file($conf_dir + 'console-password.yaml')

# Apply ERB template and save result to file
def write_conman_file(site_uid, site_refapi, site_config, site_credentials)
  output = ERB.new(File.read("templates/conman.erb")).result(binding)

  output_file = Pathname("#{$output_dir}/modules/conmang5k/files/#{site_uid}/conman.conf")
  output_file.dirname.mkpath()
  File.write(output_file, output)
end

# Loop over each site
refapi["sites"].each { |site_uid, site_refapi|
  write_conman_file(site_uid, site_refapi, config[site_uid], credentials[site_uid])
}
