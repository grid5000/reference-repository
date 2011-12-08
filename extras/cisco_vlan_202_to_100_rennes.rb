#!/usr/bin/env ruby
# Author:: Pascal Morillon (<pascal.morillon@irisa.fr>)
# Date:: Thu Dec 08 15:48:23 +0100 2011
#

require 'yaml'

site        = 'rennes'
clusters    = %w{paramount paradent parapide parapluie}
primary_eth = {
              "paramount" => "eth0",
              "paradent"  => "eth0",
              "parapide"  => "eth0",
              "parapluie" => "eth1"
}
not_referenced = []

conf = ""
clusters.each do |cluster|
  yamldoc = YAML.load(File.read(File.join("generators", "input", "#{site}-#{cluster}.yaml")))
  nodes = yamldoc.sort { |a,b| a.first.split('-')[1].to_i <=> b.first.split('-')[1].to_i }

  nodes.each do |node|
    if node.last["network_interfaces"][primary_eth[cluster]]["switch_port"].nil?
      not_referenced << node.first
      next
    end
    conf += "!\n"
    conf += "interface GigabitEthernet#{node.last["network_interfaces"][primary_eth[cluster]]["switch_port"].split('i').last}\n"
    conf += " description #{node.first}\n"
    conf += " switchport access vlan 100\n"
  end
end
conf += "!\n"
puts conf
if not_referenced.length > 0
  STDERR.puts "Not referenced nodes :"
  STDERR.puts not_referenced.inspect
end
