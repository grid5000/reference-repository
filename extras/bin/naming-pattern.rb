#!/usr/bin/env ruby

ROOT_DIR = File.expand_path('../..', __FILE__)
LIB_DIR = File.join(ROOT_DIR, "lib")
$LOAD_PATH.unshift LIB_DIR unless $LOAD_PATH.include?(LIB_DIR)

require 'naming-pattern'

#naming_pattern = "Vlan%VLANID%"
#naming_pattern = "Po%CHANNELID%"
#naming_pattern = "Te%LINECARD%/%PORT%"
#naming_pattern = "Gi%LINECARD%/%PORT%"

naming_pattern = "Gi%LINECARD%/%PORT%"
#naming_pattern = "Gi%UNO:sd:1%/%DOS:1%"
naming_pattern = "%LINECARD:A%%PORT%"
#ifname = "Gi2/7"
ifname = "D4"

def usage
  puts "Usage : #{ENV["_"]} naming_pattern interface"
end
if ARGV.size != 2
  usage
  exit!
end
naming_pattern,ifname = ARGV

dict = NamingPattern.encode(naming_pattern,ifname)
puts "#{naming_pattern} + #{ifname} \t  => \t #{dict.inspect}"

ifname = NamingPattern.decode(naming_pattern,dict)
puts "#{naming_pattern} + #{dict.inspect} \t => \t #{ifname.inspect}"

