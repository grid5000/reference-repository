#!/usr/bin/env ruby
# Author:: Pascal Morillon (<pascal.morillon@irisa.fr>)
# Date:: Thu Dec 08 13:47:03 +0100 2011
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

clusters.each do |cluster|
  conf = ""
  yamldoc = YAML.load(File.read(File.join("generators", "input", "#{site}-#{cluster}.yaml")))
  nodes = yamldoc.sort { |a,b| a.first.split('-')[1].to_i <=> b.first.split('-')[1].to_i }
  conf += "# Cluster #{cluster} - production network vlan100\n"
  conf += "group {\n"
  conf += "\n"
  nodes.each do |node|
    conf += "  host #{node.first} {\n"
    conf += "    hardware ethernet #{node.last["network_interfaces"][primary_eth[cluster]]["mac"]};\n"
    conf += "    fixed-address #{node.last["network_interfaces"][primary_eth[cluster]]["ip"]};\n"
    conf += "  }\n"
    conf += "\n"
  end
  conf += "}\n"
  conf += "\n"
  conf += "\n"
  conf += "# Cluster #{cluster} - management network vlan101\n"
  conf += "group {\n"
  conf += "\n"
  nodes.each do |node|
    conf += "  host #{node.first}-bmc {\n"
    conf += "    hardware ethernet #{node.last["network_interfaces"]["bmc"]["mac"]};\n"
    conf += "    fixed-address #{node.last["network_interfaces"]["bmc"]["ip"]};\n"
    conf += "  }\n"
    conf += "\n"
  end
  conf += "}\n"
  conf += "\n"
  conf += "\n"
  puts conf
end
