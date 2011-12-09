#!/usr/bin/env ruby
# Author:: Pascal Morillon (<pascal.morillon@irisa.fr>)
# Date:: Wed Dec 07 14:14:02 +0100 2011
#

require 'yaml'

$cluster = "parapluie"


case $cluster
when "paramount"
  $site         = "rennes"
  $default_eth  = "eth0"
  $hp_net       = "myri0"
  $ip_prefix    = "172.16.96"
  $nb_nodes     = 33
when "paradent"
  $site         = "rennes"
  $default_eth  = "eth0"
  $hp_net       = false
  $ip_prefix    = "172.16.97"
  $nb_nodes     = 64
when "parapide"
  $site         = "rennes"
  $default_eth  = "eth0"
  $hp_net       = "ib0"
  $ip_prefix    = "172.16.98"
  $nb_nodes     = 25
when "parapluie"
  $site         = "rennes"
  $default_eth  = "eth1"
  $hp_net       = "ib0"
  $ip_prefix    = "172.16.99"
  $nb_nodes     = 40
else
  raise "Cluster #{$cluster} is not yet supported ! Check script code..."
end

yamldoc = YAML.load(File.read(File.join("generators", "input", "#{$site}-#{$cluster}.yaml")))

(1..$nb_nodes).each do |index|
  ip_tab = $ip_prefix.split('.')
  eth_ip = (ip_tab << index.to_s).join('.')
  bmc_ip = [ip_tab[0], "17", ip_tab[2], index.to_s].join('.')
  hp_ip = [ip_tab[0], "18", ip_tab[2], index.to_s].join('.')

  yamldoc["#{$cluster}-#{index}"]["network_interfaces"]["bmc"]["ip"] = bmc_ip
  yamldoc["#{$cluster}-#{index}"]["network_interfaces"][$default_eth]["ip"] = eth_ip
  yamldoc["#{$cluster}-#{index}"]["network_interfaces"][$hp_net]["ip"] = hp_ip if $hp_net

end

puts yamldoc.to_yaml

