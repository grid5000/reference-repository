#!/usr/bin/ruby

require 'pp'
require 'erb'
require 'pathname'
require '../lib/input_loader'

refapi = load_yaml_file_hierarchy("../input/grid5000/")
$output_dir = ENV['puppet_repo'] || 'output'

# Create a dns entry from:
# entry = 
# {:cluster_uid=>"talc",
#  :net_uid=>"eth0",
#  :start=>134,
#  :end=>134,
#  :ip=>"172.16.66",
#  :shift=>0,
#  :mounted=>true}
def print_entry(entry)
  if entry[:start] == entry[:end]
    return "#{entry[:cluster_uid]}-#{entry[:start]}-#{entry[:net_uid]} IN A #{entry[:ip]}.#{entry[:start]+entry[:shift]}"
  else 
    range = "#{entry[:start]}-#{entry[:end]}"
    shift = (entry[:shift] > 0 ? '{+' + entry[:shift].to_s  + '}' : '')
    ip    = "#{entry[:ip]}.$#{shift}"
    
    if entry[:mounted] && /^eth[0-9]$/.match(entry[:net_uid])
      # primary interface
      return ["$GENERATE #{range} #{entry[:cluster_uid]}-$ IN A #{ip}",
              "$GENERATE #{range} #{entry[:cluster_uid]}-$-#{entry[:net_uid]} IN CNAME #{entry[:cluster_uid]}-$"].join("\n")

    elsif /^kavlan-[0-9]*$/.match(entry[:net_uid])
      return ["$GENERATE #{range} #{entry[:cluster_uid]}-$-eth0-#{entry[:net_uid]} IN A #{ip}",
              "$GENERATE #{range} #{entry[:cluster_uid]}-$-#{entry[:net_uid]} IN CNAME #{entry[:cluster_uid]}-$-eth0-#{entry[:net_uid]}"].join("\n")
    else
      return "$GENERATE #{range} #{entry[:cluster_uid]}-$-#{entry[:net_uid]} IN A #{ip}"
    end 
  end 
end

# def write_bind_file(data)
#   output = ERB.new(File.read("templates/bind.erb")).result(binding)

#   output_file = Pathname("#{$output_dir}/modules/bindg5k/files/zones/#{data.fetch('site_uid')}/#{data.fetch('site_uid')}.db")
#   output_file.dirname.mkpath()

#   File.write(output_file, output)
# end

# Loop over Grid'5000 sites

refapi["sites"].each { |site_uid, site|
  next if site_uid != 'nancy'

  entries = {}

  site.fetch("clusters").sort.each { |cluster_uid, cluster|
    #next if cluster_uid != 'griffon'

    cluster.fetch('nodes').each_sort_by_node_uid { |node_uid, node|

      network_adapters = {}

      node.fetch('network_adapters').each { |net_uid, net_hash|
        network_adapters[net_uid] = {"ip"=>net_hash["ip"], "mounted"=>net_hash["mounted"]}
      }

      node.fetch('kavlan').each { |net_uid, ip|
        network_adapters[net_uid] = {"ip"=>ip, "mounted"=>nil}
      } if node['kavlan']

      # Group ip ranges
      network_adapters.each { |net_uid, net_hash|
        next unless net_hash['ip']

        entries[cluster_uid] ||= {}
        entries[cluster_uid][net_uid] ||= []
        last_entry = entries[cluster_uid][net_uid].last

        node_id = node_uid.to_s.split(/(\d+)/)[1].to_i # node number
        ip = net_hash['ip']
        ip_array = ip.split('.')

        if last_entry and ip == last_entry[:ip] + '.' + (node_id + last_entry[:shift]).to_s and last_entry[:end] == node_id-1 and net_hash['mounted'] == last_entry[:mounted]
          last_entry[:end] += 1
        else

          # new range
          new_entry = {
            :cluster_uid => cluster_uid,
            :net_uid => net_uid,
            :start   => node_id,
            :end     => node_id,
            :ip      => ip_array[0..2].join("."),
            :shift   => ip_array[3].to_i - node_id,
            :mounted => net_hash["mounted"]
          }
          
          entries[cluster_uid][net_uid] << new_entry
        end
      }
      
    } # each node

  } # each cluster
  

  #
  #
  #

  output = []
  entries.each { |cluster_uid, cluster_entries|
    cluster_entries.each { |net_uid, entries|
        entries.each { |entry|
        output << print_entry(entry)
      } 
    }
  }
  
  output_file = Pathname("#{$output_dir}/modules/bindg5k/files/zones/#{site_uid}/#{site_uid}.db")
  output_file.dirname.mkpath()
  File.write(output_file, output.join("\n"))
  
} # each sites

