#!/usr/bin/ruby

if RUBY_VERSION < "2.1"
  puts "This script requires ruby >= 2.1"
  exit
end

# See also: https://www.grid5000.fr/mediawiki/index.php/DNS_server

require 'pp'
require 'erb'
require 'pathname'
require '../lib/input_loader'

refapi = load_yaml_file_hierarchy("../input/grid5000/")
$output_dir = ENV['puppet_repo'] || 'output'

# Create a dns entry
# $GENERATE 1-16 graoully-$-bmc IN A 172.17.70.$
#
# $GENERATE 1-16 graoully-$ IN A 172.16.70.$
# $GENERATE 1-16 graoully-$-eth0 IN CNAME graoully-$
#
# $GENERATE 1-16 graoully-$-eth0-kavlan-3 IN A 192.168.233.$
# $GENERATE 1-16 graoully-$-kavlan-3 IN CNAME graoully-$-eth0-kavlan-3
#
def print_entry(entry)
  if entry[:start].nil?
    range     = ""
    hostshort = entry[:uid]
    ip        = entry[:ip]
  elsif entry[:start] == entry[:end]
    range     = ""
    hostshort = "#{entry[:uid]}-#{entry[:start]}"                             # graoully-1
    ip        = "#{entry[:ip]}.#{entry[:start]+entry[:shift]}"                # 172.16.70.1
  else
    range     = "$GENERATE #{entry[:start]}-#{entry[:end]} "                  # $GENERATE 1-16
    hostshort = "#{entry[:uid]}-$"                                    # graoully-$
    shift     = (entry[:shift] > 0 ? '{+' + entry[:shift].to_s  + '}' : '')   
    ip        = "#{entry[:ip]}.$#{shift}"                                     # 172.16.70.$
  end

  hostname  = entry[:hostsuffix] ? hostshort + entry[:hostsuffix] : hostshort # graoully-$-eth0

  if entry[:cnamesuffix]
    hostalias = hostshort + entry[:cnamesuffix]
    return ["#{range}#{hostalias} IN A #{ip}",
            "#{range}#{hostname} IN CNAME #{hostalias}"].join("\n")
  else
    return "#{range}#{hostname} IN A #{ip}"
  end 
  
end

# Loop over Grid'5000 sites

refapi["sites"].each { |site_uid, site|
  next if site_uid != 'nancy'

  entries = {}

  ["networks", "laptops", "dom0"].each { |key|
    entries[key] ||= []
    
    site[key].each { |uid, node| 
      if node['network_adapters'].nil?
        puts "Warning: no network_adapters for #{uid}" 
        next
      end

      eth_net_uid = node['network_adapters'].select{ |u, h| h['mounted'] && /^eth[0-9]$/.match(u) } # eth* interfaces
      node['network_adapters'].each { |net_uid, net_hash|
        hostsuffix = nil
        if ! eth_net_uid.include?(net_uid) && node['network_adapters'].size > 1
          hostsuffix = "-#{net_uid}"
        end
          

        new_entry = {
          :uid         => uid,
          :hostsuffix  => hostsuffix, # cacahuete vs. cacahuete-eth0
          :ip          => net_hash['ip'],
        }
        
        entries[key] << new_entry
      }
    }
  }

  # PDUs
  entries['pdus'] ||= []
  site['pdus'].each { |pdu_uid, pdu|
    if pdu['ip']

      new_entry = {
        :uid     => pdu_uid,
        :ip      => pdu['ip']
      }

      entries['pdus'] << new_entry

    end
  }
  
  site.fetch("clusters").sort.each { |cluster_uid, cluster|
    #next if cluster_uid != 'griffon'

    cluster.fetch('nodes').each_sort_by_node_uid { |node_uid, node|
      network_adapters = {}

      # Nodes
      node.fetch('network_adapters').each { |net_uid, net_hash|
        network_adapters[net_uid] = {"ip" => net_hash["ip"], "mounted" => net_hash["mounted"]}
      }
      
      # Kavlan
      node.fetch('kavlan').each { |net_uid, net_hash|
        net_hash.each { |kavlan_net_uid, ip|
          network_adapters["#{net_uid}-#{kavlan_net_uid}"] = {"ip" => ip, "mounted" => nil}
        } 
      } if node['kavlan']

      # Mic
      if node['mic'] && node['mic']['ip']
        network_adapters['mic0'] = {"ip" => node['mic']['ip']}
      end
      
      # Group ip ranges
      network_adapters.each { |net_uid, net_hash|
        next unless net_hash['ip']
        
        entries["#{cluster_uid}-#{net_uid}"] ||= []
        last_entry = entries["#{cluster_uid}-#{net_uid}"].last
        
        node_id = node_uid.to_s.split(/(\d+)/)[1].to_i # node number
        ip = net_hash['ip']
        ip_array = ip.split('.')
        
        if last_entry and ip == last_entry[:ip] + '.' + (node_id + last_entry[:shift]).to_s and last_entry[:end] == node_id-1
          last_entry[:end] += 1
        else
          
          # CNAME entries
          hostsuffix  = "-#{net_uid}"
          cnamesuffix = nil # no CNAME entry by default
          if net_hash['mounted'] && /^eth[0-9]$/.match(net_uid)
            # primary interface
            cnamesuffix = '' # CNAME enabled for primary interface
          elsif /^*-kavlan-[0-9]*$/.match(net_uid)
            # kavlan
            net_primaries = network_adapters.select{ |u, h| h['mounted'] && /^eth[0-9]$/.match(u) } # list of primary interfaces
            net_uid_eth, net_uid_kavlan = net_uid.to_s.scan(/^([^-]*)-(.*)$/).first # split 'eth0-kavlan-1'

            # CNAME only for primary interface kavlan
            if net_primaries.include?(net_uid_eth)
              hostsuffix  = "-#{net_uid_kavlan}" # -kavlan-1
              cnamesuffix = "-#{net_uid}"        # -eth0-kavlan-1
            end
          end
          
          # new range
          new_entry = {
            :uid         => cluster_uid,
            :hostsuffix  => hostsuffix, # -eth0, -kavlan-1
            :cnamesuffix => cnamesuffix,   # graoully-$-, graoully-$-eth0-kavlan-1
            :start       => node_id,
            :end         => node_id,
            :ip          => ip_array[0..2].join("."),
            :shift       => ip_array[3].to_i - node_id,
          }
          
          entries["#{cluster_uid}-#{net_uid}"] << new_entry
        end
      }

    } # each nodes
    
    
  } # each cluster
  

  #
  # Output
  #

  output = []
  entries.each { |type, e|
    e.each { |entry|
      output << print_entry(entry)
    }
  }
  
  output_file = Pathname("#{$output_dir}/modules/bindg5k/files/zones/#{site_uid}/#{site_uid}-clusters.db")
  output_file.dirname.mkpath()
  File.write(output_file, output.join("\n"))
  
} # each sites

