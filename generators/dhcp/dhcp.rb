#!/usr/bin/ruby

require 'pp'
require 'erb'
require 'fileutils'
require '../lib/input_loader'

global_hash = load_yaml_file_hierarchy("../../input/grid5000/")
#puts JSON.generate(data)

["bmc", "eth"].each { |network_interface|
  
  global_hash["sites"].each { |site_uid, site_hash|
    # next unless site_uid == "nancy"
    
    erb = ERB.new(File.read("templates/dhcp.erb"))
    output_file = "output/puppet-repo/modules/dhcpg5k/files/" + site_uid + "/dhcpd.conf.d/" + network_interface #site_hash["network_interfaces"][network_interface]["ip"]
    pp output_file

    # Create directory hierarchy
    dirname = File.dirname(output_file)
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    
    # Apply ERB template and save
    File.open(output_file, "w+") { |f|
      f.write(erb.result(binding))
    }
    
  }
}
