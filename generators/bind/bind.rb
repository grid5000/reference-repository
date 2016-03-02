#!/usr/bin/ruby

require 'pp'
require 'erb'
require 'fileutils'
require '../lib/input_loader'

global_hash = load_yaml_file_hierarchy("../../input/grid5000/")

def write_bind_file(data)
  erb = ERB.new(File.read("templates/bind.erb"))
  filename = data.fetch("site_uid") + ".db"
  output_file = "output/puppet-repo/modules/bindg5k/files/zones/" + data.fetch("site_uid") + "/" + filename

  # Create directory hierarchy
  dirname = File.dirname(output_file)
  FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

  # Apply ERB template and save
  File.open(output_file, "w+") { |f|
    f.write(erb.result(binding))
  }
end

# Loop over Grid'5000 sites

# Ex:
# {"parapide"=>
#   {"eth0"=>[{"start"=>1, "end"=>25, "ip"=>"172.16.98", "shift"=>0}],
#    "ib0"=>[{"start"=>1, "end"=>25, "ip"=>"172.18.98", "shift"=>0}],
#    "bmc"=>[{"start"=>1, "end"=>25, "ip"=>"172.17.98", "shift"=>0}]}}

global_hash["sites"].each { |site_uid, site_hash|

  entries = {}

  site_hash.fetch("clusters").sort.each { |cluster_uid, cluster_hash|

    cluster_hash.fetch('nodes').each_sort_by_node_uid { |node_uid, node_hash|

      network_interfaces = {}
      node_hash.fetch('network_interfaces').each { |net_uid, net_hash|
        network_interfaces[net_uid] = {"ip"=>net_hash["ip"], "mounted"=>net_hash["mounted"]}
      }
      node_hash.fetch('kavlan').each { |net_uid, ip|
        network_interfaces[net_uid] = {"ip"=>ip, "mounted"=>nil}
      } if node_hash['kavlan']

      network_interfaces.each { |net_uid, net_hash|

        entries[cluster_uid] = {}          unless entries[cluster_uid]
        entries[cluster_uid][net_uid] = [] unless entries[cluster_uid][net_uid]
        last_entry = entries[cluster_uid][net_uid].last

        next unless net_hash["ip"]

        node_id = node_uid.to_s.split(/(\d+)/)[1].to_i # node number
        ip = net_hash["ip"]
        ip_array = ip.split(".")

        if last_entry and ip == last_entry["ip"] + "." + (node_id + last_entry["shift"]).to_s and last_entry["end"] == node_id-1 and net_hash["mounted"] == last_entry["mounted"]
          last_entry["end"] = last_entry["end"] + 1
        else
          new_entry = {}
          new_entry["start"]   = node_id
          new_entry["end"]     = node_id
          new_entry["ip"]      = ip_array[0..2].join(".")
          new_entry["shift"]   = ip_array[3].to_i - node_id
          new_entry["mounted"] = net_hash["mounted"]
          entries[cluster_uid][net_uid] << new_entry
        end
      }
    }

  }

  pp entries
  pp "--"
  write_bind_file({
                    "filename"            => site_uid + ".db",
                    "site_uid"            => site_uid,
                    "entries"             => entries,
                  })
  
  
}
