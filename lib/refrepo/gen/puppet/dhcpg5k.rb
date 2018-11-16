#!/usr/bin/ruby

if RUBY_VERSION < "2.1"
  puts "This script requires ruby >= 2.1"
  exit
end

require 'pp'
require 'erb'
require 'pathname'
require 'optparse'
require_relative '../lib/input_loader'

input_data_dir = "../../input/grid5000/"

global_hash = load_yaml_file_hierarchy(File.expand_path(input_data_dir, File.dirname(__FILE__)))

options = {}
options[:sites] = %w{grenoble lille luxembourg lyon nancy nantes rennes sophia}
options[:output_dir] = "/tmp/puppet-repo"

OptionParser.new do |opts|
  opts.banner = "Usage: dhcpg5k.rb [options]"

  opts.separator ""
  opts.separator "Example: ruby dhcpg5k.rb -s nancy -o /tmp/puppet-repo"

  opts.on('-o', '--output-dir dir', String, 'Select the puppet repo path', "Default: " + options[:output_dir]) do |d|
    options[:output_dir] = d
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

# Get the mac and ip of a node. Throw exception if error.
def get_network_info(node_hash, network_interface)
  # Get node_hash["network_adapters"][network_interface]["ip"] and node_hash["network_adapters"][network_interface]["mac"]
  node_network_adapters = node_hash.fetch("network_adapters")

  # For the production network, find the mounted interface (either eth0 or eth1)
  neti = network_interface
  if neti == "eth" then
    (0..5).each {|i|
      if node_network_adapters.fetch("eth#{i}").fetch("mounted")
        neti = "eth#{i}"
        break
      end
    }
    raise 'none of the eth[0-4] interfaces have the property "mounted" set to "true"' if neti == 'eth'
  end

  node_network_interface = node_network_adapters.fetch(neti)

  raise '"mac" is nil' unless node_mac = node_network_interface.fetch("mac")
  raise '"ip" is nil'  unless node_ip  = node_network_interface.fetch("ip")

  return [node_ip, node_mac]
end

def write_dhcp_file(data, options)
  if data["nodes"].nil?
    puts "Error in #{__method__}: no entry for \"#{data['filename']}\" at #{data['site_uid']} (#{data['network_adapters']})."
    return ""
  end

  output = ERB.new(File.read(File.expand_path('templates/dhcp.erb', File.dirname(__FILE__)))).result(binding)
  output_file = Pathname("#{options[:output_dir]}/platforms/production/modules/generated/files/grid5000/dhcp/#{data.fetch("site_uid")}/#{data.fetch('filename')}")
  output_file.dirname.mkpath()
  File.write(output_file, output)
end

puts "Writing DHCP configuration files to: #{options[:output_dir]}"
puts "For site(s): #{options[:sites].join(', ')}"

# Loop over Grid'5000 sites
global_hash["sites"].each { |site_uid, site_hash|

  next unless options[:sites].include?(site_uid)

  puts site_uid

  #
  # eth, bmc and mic0
  #

  # Relocate ip/mac info of MIC
  site_hash.fetch("clusters").each { |cluster_uid, cluster_hash|
    cluster_hash.fetch('nodes').each { |node_uid, node_hash|
      next if node_hash == nil || node_hash['status'] == 'retired'

      if node_hash['mic'] && node_hash['mic']['ip'] && node_hash['mic']['mac']
        node_hash['network_adapters'] ||= {}
        node_hash['network_adapters']['mic0'] ||= {}
        node_hash['network_adapters']['mic0']['ip']  = node_hash['mic'].delete('ip')
        node_hash['network_adapters']['mic0']['mac'] = node_hash['mic'].delete('mac')
      end
    }
  }

  # One file for each clusters
  site_hash.fetch("clusters").each { |cluster_uid, cluster_hash|
    # networks = ["eth", "bmc"]
    # networks << 'mic0' if cluster_hash['nodes'].values.any? {|x| x['network_adapters']['mic0'] }

    write_dhcp_file({
                      "filename"            => "cluster-" + cluster_uid + ".conf",
                      "site_uid"            => site_uid,
                      "nodes"               => cluster_hash.fetch('nodes'),
                      "network_adapters"    => ["eth", "bmc", "mic0"],
                      "optional_network_adapters"  => ["mic0"]
                    }, options)
  }

  #
  #
  #

  # Other dhcp files
  ["networks", "laptops", "servers"].each { |key|
    write_dhcp_file({
                      "filename"            => key + ".conf",
                      "site_uid"            => site_uid,
                      "nodes"               => site_hash[key],
                      "network_adapters"    => ["default", "eth", "bmc", "adm"],
                      "optional_network_adapters"  => ["eth", "bmc", "adm"]
                    }, options) unless site_hash[key].nil?
  }

  #
  # PDUs
  #

  if ! site_hash['pdus'].nil?
    # Relocate ip/mac info of PDUS
    site_hash['pdus'].each { |pdu_uid, pdu_hash|
      if pdu_hash['ip'] && pdu_hash['mac']
        pdu_hash['network_adapters'] ||= {}
        pdu_hash['network_adapters']['pdu'] ||= {}
        pdu_hash['network_adapters']['pdu']['ip']  = pdu_hash.delete('ip')
        pdu_hash['network_adapters']['pdu']['mac'] = pdu_hash.delete('mac')
      end
    }

    key = 'pdus'
    write_dhcp_file({
                      "filename"            => key + ".conf",
                      "site_uid"            => site_uid,
                      "nodes"               => site_hash['pdus'],
                      "network_adapters"  => ['pdu'],
                      "optional_network_adapters"  => []
                    }, options)
  end

}
