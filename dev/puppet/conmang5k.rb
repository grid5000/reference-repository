#!/usr/bin/ruby

require 'pp'
require 'erb'
require 'fileutils'
require '../lib/input_loader'
require '../lib/hash/hash.rb'

global_hash = load_yaml_file_hierarchy("../input/grid5000/")
passwd_hash = YAML::load_file('./conman-password.yaml')
passwd_hash = passwd_hash.expand_square_brackets()

def write_conman_file(site_uid, site, passwd)
  erb = ERB.new(File.read("templates/conman.erb"))
  output_file = File.join('output', 'conmang5k', 'files', site_uid, 'conman.conf')
  
  # Create directory hierarchy
  dirname = File.dirname(output_file)
  FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
  
  # Apply ERB template and save
  File.open(output_file, "w+") { |f|
    f.write(erb.result(binding))
  }
end

# Loop over Grid'5000 sites
global_hash["sites"].each { |site_uid, site|
  write_conman_file(site_uid, site, passwd_hash[site_uid])
}
