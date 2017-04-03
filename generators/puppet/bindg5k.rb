#!/usr/bin/ruby

if RUBY_VERSION < "2.1"
  puts "This script requires ruby >= 2.1"
  exit
end

# See also: https://www.grid5000.fr/mediawiki/index.php/DNS_server

require 'pp'
require 'erb'
require 'pathname'
require 'fileutils'
require 'optparse'
require_relative '../lib/input_loader'

input_data_dir = "../../input/grid5000/"

refapi = load_yaml_file_hierarchy(File.expand_path(input_data_dir, File.dirname(__FILE__)))

options = {}
options[:sites] = %w{grenoble lille luxembourg lyon nancy nantes rennes sophia}
options[:output_dir] = "/tmp/puppet-repo"

OptionParser.new do |opts|
  opts.banner = "Usage: bindg5k.rb [options]"

  opts.separator ""
  opts.separator "Example: ruby bindg5k.rb -s nancy -o /tmp/puppet-repo"

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

def write_site_zones(site_uid, site, zones_dir, dns_entries)

  site_zone_content = "\n"

  dns_entries.each { |type, entries|

    next if entries["addr"].empty?

    file_name = site_uid + "-" + type + ".db"
    site_zone_content += "$INCLUDE /etc/bind/zones/#{site_uid}/#{file_name}\n"
 
    output_file = File.join(zones_dir, file_name)
    FileUtils.mkdir_p(File.dirname(output_file))
    header = ERB.new(File.read(File.expand_path('templates/bind-header.erb', File.dirname(__FILE__)))).result(binding)
    File.write(output_file, header + "\n" + entries["addr"].join("\n") + "\n\n", node: 'wa+')
    if (! entries["cnames"].empty?)
      File.write(output_file, "\n; CNAMES\n" + entries["cnames"].join("\n") + "\n\n", mode: 'a')
    end
    $written_files << output_file
  }

  # DNS (/modules/bindg5k/files/zones/nancy.db)
  manual = site_uid + '-manual.db'
  if File.exist?(File.join(zones_dir, manual)) # add include statement
    site_zone_content += "$INCLUDE /etc/bind/zones/#{site_uid}/#{manual}\n\n"
  end

  output_file = site_uid + '.db'
  header = ERB.new(File.read(File.expand_path('templates/bind-header.erb', File.dirname(__FILE__)))).result(binding)
  FileUtils.mkdir_p(File.dirname(File.join(zones_dir, output_file)))
  File.write(File.join(zones_dir, output_file), header + "\n" + site_zone_content)
  $written_files << File.join(zones_dir, output_file).to_s
end

def write_reverse_site_zones(site_uid, zones_dir, reverse_entries)

  #Reverse DNS (/modules/bindg5k/files/zones/reverse-*db)
  reverse_entries.each { |output_file, output|
    header = ERB.new(File.read(File.expand_path('templates/bind-header.erb', File.dirname(__FILE__)))).result(binding) # do not move outside of the loop (it uses the output_file variable)
    manual = output_file.sub('.db', '') + '-manual.db'
    output.unshift("$INCLUDE /etc/bind/zones/#{site_uid}/#{manual}") if File.exist?(File.join(zones_dir, manual))
    FileUtils.mkdir_p(File.dirname(File.join(zones_dir, output_file)))
    File.write(File.join(zones_dir, output_file), header + output.join("\n") + "\n")
    $written_files << File.join(zones_dir, output_file).to_s
  }

  #Create reverse-*.db files for each reverse-*-manual.db that do not have (yet) a corresponding file.
  Dir.glob(File.join("#{zones_dir}", "reverse-*-manual.db")).each { |reverse_manual_file|
    reverse_manual_file = File.basename(reverse_manual_file);
    output_file = reverse_manual_file.sub("-manual.db", ".db")
    next if File.exists?(File.join(zones_dir, output_file))
    puts "Including orphan reverse manual file: #{reverse_manual_file}"
    header = ERB.new(File.read(File.expand_path('templates/bind-header.erb', File.dirname(__FILE__)))).result(binding)
    content = "$INCLUDE /etc/bind/zones/#{site_uid}/#{reverse_manual_file}"
    FileUtils.mkdir_p(File.dirname(File.join(zones_dir, output_file)))
    File.write(File.join(zones_dir, output_file), header + "\n" + content + "\n")
    $written_files << File.join(zones_dir, output_file).to_s
  }
end

# files/global/conf/global-nancy.conf
# files/site/conf/global-nancy.conf
#zones_dir needed in erb
def write_global_site_conf(site_uid, dest_dir, zones_dir)

  ['global', 'site'].each { |dir|
    conf_file = File.join(dest_dir, "#{dir}/conf", "global-#{site_uid}.conf")
    FileUtils.mkdir_p(File.dirname(conf_file))
    conf_content = ERB.new(File.read(File.expand_path('templates/bind-global-site.conf.erb', File.dirname(__FILE__)))).result(binding)
    File.write(conf_file, conf_content)
  }
end

# Create a dns entry
def print_entry(entry)
  max_pad = 30 #Sane default for maximum hostname length
  addr = []
  cnames = []
  hostshort = entry[:uid]
  hostshort += "-" + entry[:node_uid].to_s if entry[:node_uid]
  ip        = entry[:ip]
  hostname  = entry[:hostsuffix] ? hostshort + entry[:hostsuffix] : hostshort # graoully-$-eth0

  if entry[:cnamesuffix]
    hostalias = hostshort + entry[:cnamesuffix]
    addr << "#{hostalias.ljust(max_pad)} IN A #{' ' * 6 + ip}"
    cnames << "#{hostname.ljust(max_pad)} IN CNAME #{' ' * 6 + hostalias}"
    #If there are cnames defined, point cnames to defined hostname instead
    hostname = hostalias
  else
    addr << "#{hostname.ljust(max_pad)} IN A #{' ' * 6 + ip}"
  end
  if entry[:cnames]
    entry[:cnames].each{ |cname|
      cnames << "#{cname.ljust(max_pad)} IN CNAME #{' ' * 6 + hostname}"
    }
  end
  return addr, cnames
end

# Examples: reverse-64.16.172.db
# 96                                 IN      PTR     opensm.nancy.grid5000.fr.
def print_reverse_entry(site_uid, entry)
  hostshort = entry[:uid]
  hostshort += "-" + entry[:node_uid].to_s if entry[:node_uid]
  ipsuffix = entry[:ip].split(".")[3]
  file = "#{entry[:ip].split('.')[0..2].reverse.join('.')}" # 70.16.172

  if entry[:cnamesuffix].nil?
    hostname  = entry[:hostsuffix] ? hostshort + entry[:hostsuffix] : hostshort # graoully-$-eth0
  else
    hostname  = hostshort + entry[:cnamesuffix]
  end
  return ["reverse-#{file}.db", "#{ipsuffix} IN PTR #{hostname}.#{site_uid}.grid5000.fr."]
end

def get_servers_entries(site)
  entries = []

  site['servers'].sort.each { |server_uid, server|

    next if server['network_adapters'].nil?

    server['network_adapters'].each { |net_uid, net|

      next if net['ip'].nil?

      new_entry = {
        :uid         => server_uid,
        :hostsuffix  => net_uid != 'default' ? "-#{net_uid}" : '',
        :ip          => net['ip']
      }
      if server['alias']
        new_entry[:cnames] = server['alias'].reject{ |cname| cname.include?('.') }.map{ |cname|
          net_uid == 'default' ? cname : "#{cname}-#{net_uid}"
        }
      end
      entries << new_entry
    }
  }

  return entries
end

def get_pdus_entries(site)
  entries = []

  site['pdus'].sort.each { |pdu_uid, pdu|

    next unless pdu['ip']

    new_entry = {
      :uid     => pdu_uid,
      :ip      => pdu['ip']
    }
    entries << new_entry
  }
  return entries
end

def get_networks_entries(site, key)
  entries = []

  site[key].sort.each { |uid, node|
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
      entries << new_entry
    }
  }
  return entries
end

def get_node_entries(cluster_uid, node_uid, network_adapters)

  entries = {}

  network_adapters.each { |net_uid, net_hash|

    next unless net_hash['ip']

    node_id = node_uid.to_s.split(/(\d+)/)[1].to_i # node number
    ip = net_hash['ip']

    hostsuffix  = "-#{net_uid}"
    cnamesuffix = nil # no CNAME entry by default

    if net_hash['mounted'] && /^eth[0-9]$/.match(net_uid)
      #primary interface
      cnamesuffix = '' # CNAME enabled for primary interface (node-id-iface cname node-id)
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
    new_entry = {
      :uid         => cluster_uid,
      :hostsuffix  => hostsuffix, # -eth0, -kavlan-1
      :cnamesuffix => cnamesuffix,   # graoully-$-, graoully-$-eth0-kavlan-1
      :node_uid    => node_id,
      :ip          => ip
    }
    #Handle interface aliases
    if (net_hash["alias"])
      new_entry[:cnames] ||= []
      net_hash["alias"].each { |cname|
        new_entry[:cnames] << "#{cluster_uid}-#{node_id}-#{cname}"
      }
    end
    #Group entries by cluster and cluster-kavlan
    if (/kavlan/.match(net_uid))
      entries["#{cluster_uid}-kavlan"] ||= []
      entries["#{cluster_uid}-kavlan"] << new_entry
    else
      entries["#{cluster_uid}"] ||= []
      entries["#{cluster_uid}"] << new_entry
    end
  } #each network adapters
  return entries
end

puts "Writing DNS configuration files to: #{options[:output_dir]}"
puts "For site(s): #{options[:sites].join(', ')}"

$written_files = []

# Loop over Grid'5000 sites
refapi["sites"].each { |site_uid, site|

  next unless options[:sites].include?(site_uid)

  entries = {}

  # Servers
  entries['servers'] = get_servers_entries(site) unless site['servers'].nil?

  # PDUs
  entries['pdus'] = get_pdus_entries(site) unless site['pdus'].nil?

  # Networks and laptops (same input format)
  entries['networks'] = get_networks_entries(site, 'networks') unless site['networks'].nil?
  entries['laptops'] = get_networks_entries(site, 'laptops') unless site['laptops'].nil?

  site.fetch("clusters").sort.each { |cluster_uid, cluster|

    cluster.fetch('nodes').select { |node_uid, node|
      node != nil && node["status"] != "retired" && node.has_key?('network_adapters')
    }.each_sort_by_node_uid { |node_uid, node|

      network_adapters = {}

      # Nodes
      node.fetch('network_adapters').each { |net_uid, net_hash|
        network_adapters[net_uid] = {"ip" => net_hash["ip"], "mounted" => net_hash["mounted"], "alias" => net_hash["alias"]}
      }

      # Kavlan
      if node['kavlan']
        node.fetch('kavlan').each { |net_uid, net_hash|
          net_hash.each { |kavlan_net_uid, ip|
            network_adapters["#{net_uid}-#{kavlan_net_uid}"] = {"ip" => ip, "mounted" => nil}
          }
        }
      end

      # Mic
      if node['mic'] && node['mic']['ip']
        network_adapters['mic0'] = {"ip" => node['mic']['ip']}
      end

      node_entries = get_node_entries(cluster_uid, node_uid, network_adapters)
      node_entries.each { |k, n_entries|
        entries[k] ||= []
        entries[k] += n_entries
      }
    } # each nodes
  } # each cluster

  #
  # Output
  #
  dns = {}     # one hash entry per type output file (e.g: nancy/servers.db)
  reverse = {} # one hash entry per reverse dns file
  local_reverse_list = [] # reverse zone files that include local kavlan (kavlan-1,kavlan-2,kavlan-3).

  entries.each { |type, e|

    dns[type] ||= {}
    dns[type]["addr"] ||= []
    dns[type]["cnames"] ||= []

    e.sort_by! { |entry|
      entry[:ip].split('.').map{ |octet|
        octet.to_i
      }
    }

    e.each { |entry|

      addr_entries, cname_entries = print_entry(entry)
      dns[type]["addr"] += addr_entries
      if (! cname_entries.empty?)
        dns[type]["cnames"] += cname_entries
      end

      #Reverse entries
      reverse_output_file, txt_entry = print_reverse_entry(site_uid, entry) # Reverse DNS
      if /.*-kavlan-[1-3]$/.match(entry[:hostsuffix])
        reverse_output_file.prepend("local/")
        local_reverse_list << reverse_output_file
      end

      reverse[reverse_output_file] ||= []
      reverse[reverse_output_file] << txt_entry
    }
  }

  dest_dir = "#{options[:output_dir]}/modules/bindg5k/files/"
  zones_dir = File.join(dest_dir, "zones/#{site_uid}")

  write_site_zones(site_uid, site, zones_dir, dns)

  write_reverse_site_zones(site_uid, zones_dir, reverse)

  write_global_site_conf(site_uid, dest_dir, zones_dir)

} # each sites

# Revert changes on files where only the serial has been updated
$written_files.each { |filePath|

  Dir.chdir("#{options[:output_dir]}") {
    if (Dir.exists?("./.git"))
      added_deleted = `git diff --numstat #{filePath} | cut -f1-2 | tr -d "\t "`.chomp()
      if (added_deleted == "11") #1 addition, 1 deletion
        system("git checkout -- #{filePath}")
      end
    end
  }

}
