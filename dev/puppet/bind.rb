#!/usr/bin/ruby

require 'pp'
require 'erb'
require 'pathname'
require '../lib/input_loader'

refapi = load_yaml_file_hierarchy("../input/grid5000/")
$output_dir = ENV['puppet_repo'] || 'output'

def write_bind_file(data)
  output = ERB.new(File.read("templates/bind.erb")).result(binding)

  output_file = Pathname("#{$output_dir}/modules/bindg5k/files/zones/#{data.fetch('site_uid')}/#{data.fetch('site_uid')}.db")
  output_file.dirname.mkpath()

  File.write(output_file, output)
end

# Loop over Grid'5000 sites

# Ex:
# {"parapide"=>
#   {"eth0"=>[{"start"=>1, "end"=>25, "ip"=>"172.16.98", "shift"=>0}],
#    "ib0"=>[{"start"=>1, "end"=>25, "ip"=>"172.18.98", "shift"=>0}],
#    "bmc"=>[{"start"=>1, "end"=>25, "ip"=>"172.17.98", "shift"=>0}]}}

refapi["sites"].each { |site_uid, site|

  entries = {}

  site.fetch("clusters").sort.each { |cluster_uid, cluster|
    next if site_uid != 'nancy'

    cluster.fetch('nodes').each_sort_by_node_uid { |node_uid, node|

      network_adapters = {}

      node.fetch('network_adapters').each { |net_uid, net_hash|
        network_adapters[net_uid] = {"ip"=>net_hash["ip"], "mounted"=>net_hash["mounted"]}
      }

      node.fetch('kavlan').each { |net_uid, ip|
        network_adapters[net_uid] = {"ip"=>ip, "mounted"=>nil}
      } if node['kavlan']

      network_adapters.each { |net_uid, net_hash|

        entries[cluster_uid] ||= {}
        entries[cluster_uid][net_uid] ||= []
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
