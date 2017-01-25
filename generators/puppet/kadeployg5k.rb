#!/usr/bin/ruby

# This script generates:
# - kadeployg5k/files/<site_uid>/server_conf[_dev]/clusters.conf from input/
# - kadeployg5k/files/<site_uid>/server_conf[_dev]/<cluster_uid>-cluster.conf from kadeployg5k[-dev].yaml and template/kadeployg5k.yaml.erb

if RUBY_VERSION < "2.1"
  puts "This script requires ruby >= 2.1"
  exit
end

require 'pp'
require 'erb'
require 'pathname'
require 'optparse'
require '../lib/input_loader'
require '../lib/hash/hash.rb'

global_hash = load_yaml_file_hierarchy("../../input/grid5000/")

options = {}
options[:sites] = %w{grenoble lille luxembourg lyon nancy nantes rennes sophia}
options[:output_dir] = "/tmp/puppet-repo"
options[:conf_dir] = "./conf-examples/"

OptionParser.new do |opts|
  opts.banner = "Usage: kadeployg5k.rb [options]"

  opts.separator ""
  opts.separator "Example: ruby kadeployg5k.rb -s nancy -d /tmp/puppet-repo -c $(dirname path_to_kadeployg5k.yaml)"

  opts.on('-o', '--output-dir dir', String, 'Select the puppet repo path', "Default: " + options[:output_dir]) do |d|
    options[:output_dir] = d
    options[:conf_dir] = "#{options[:output_dir]}/modules/kadeployg5k/generators/"
  end

  opts.on('-c', '--conf-dir dir', String, 'Select the conman configuration path', "Default: ./conf-examples") do |d|
    options[:conf_dir] = d
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

raise("Error: #{options[:conf_dir]} does not exist. The given configuration path is incorrect") unless Pathname(options[:conf_dir].to_s).exist?

puts "Writing Kadeploy configuration files to: #{options[:output_dir]}"
puts "Using configuration directory: #{options[:conf_dir]}"
puts "For site(s): #{options[:sites].join(', ')}"

# Compute cluster prefix
# input: cluster_list = ['graoully', 'graphene', 'griffon', ...]
# output: prefix_hash = {'grao' => 'graoully', 'graphe' => 'graphene', ...}
def cluster_prefix(cluster_list)

  # Shrink cluster names. Start with 3 characters
  # prefix_hash = {'gra' => ['graoully', 'graphene', ...], 'gri' => ['griffon']}
  prefix_hash = cluster_list.group_by { |x| x[0, 3] } 

  # Add characters until each prefix is unique
  loop do
    prefix_hash.clone.each { |k, v|
      next if v.size == 1
      prefix_hash.merge!(v.group_by { |x| x[0, k.length+1] })
      prefix_hash.delete(k)
    }
    break if prefix_hash.keys.size == cluster_list.size # no prefix duplicates
  end

  # Inverse key <=> value
  prefix_hash = Hash[prefix_hash.map {|k, v| [v[0], k] }]

end

# Extract the node ip from the node hash
def get_ip(node)
  node['network_adapters'].each { |device, network_adapter|
    if network_adapter['mounted'] && /^eth[0-9]$/.match(device)
      return network_adapter['ip']
    end
  }
end

# There is two kadeploy servers : kadeploy and kadeploy-dev
['', '-dev'].each {|suffix|

  global_hash['sites'].each { |site_uid, site|

    next unless options[:sites].include?(site_uid)

    #
    # Generate site/<site_uid>/servers_conf[_dev]/clusters.conf
    #
    
    clusters_conf = { 'clusters'=> [] } # output clusters.conf
    prefix = cluster_prefix(site['clusters'].keys)

    site['clusters'].sort.each { |cluster_uid, cluster|

      # clusters:
      # - name: griffon
      #   prefix: gri
      #   conf_file: /etc/kadeploy3/griffon-cluster.conf
      #   nodes:
      #   - name: griffon-[1-92].nancy.grid5000.fr
      #     address: 172.16.65.[1-92]

      cluster_conf = {}
      cluster_conf['name']      = cluster_uid
      cluster_conf['prefix']    = prefix[cluster_uid]
      cluster_conf['conf_file'] = "/etc/kadeploy3#{suffix}/#{cluster_uid}-cluster.conf"
      cluster_conf['nodes']     = []

      # init
      first = last = c_uid = -1
      first_ip = ['0', '0', '0', 0]

      # group nodes by range (griffon-[1-92] -> 172.16.65.[1-92])
      cluster['nodes'].each_sort_by_node_uid { |node_uid, node|

        next if node == nil || (node['status'] && node['status'] == 'retired')

        c, id = node_uid.scan(/^([^\d]*)(\d*)$/).first
        id = id.to_i
        ip = get_ip(node).split('.')
        ip[3] = ip[3].to_i

        if c == c_uid && id == last + 1 && ip[0..2] == first_ip[0..2] && ip[3] == first_ip[3] + id - first
          # extend range
          last = id
        else
          if c_uid != -1
            node = {}
            node['name']    = "#{c_uid}[#{first}-#{last}].#{site_uid}.grid5000.fr"
            node['address'] = "#{first_ip[0..2].join('.')}.[#{first_ip[3]}-#{first_ip[3]+last-first}]"
            cluster_conf['nodes'] << node
          end

          # new range
          first = last = id
          first_ip = ip
          c_uid = c
        end
      }
      # last range
      if c_uid != -1
        node = {}
        node['name']    = "#{c_uid}[#{first}-#{last}].#{site_uid}.grid5000.fr"
        node['address'] = "#{first_ip[0..2].join('.')}.[#{first_ip[3]}-#{first_ip[3]+last-first}]"
        cluster_conf['nodes'] << node
      end

      clusters_conf['clusters'] << cluster_conf

    } # site['clusters'].each

    output_file = Pathname("#{options[:output_dir]}/modules/kadeployg5k/files/#{site_uid}/server_conf#{suffix.tr('-', '_')}/clusters.conf")
    output_file.dirname.mkpath()
    write_yaml(output_file, clusters_conf)
    add_header(output_file)

    #
    # Generate <cluster_uid>-cluster.conf files
    #

    # Load 'conf/kadeployg5k.yaml' data and fill up the kadeployg5k.conf.erb template for each cluster
    
    conf = YAML::load(ERB.new(File.read("#{options[:conf_dir]}/kadeployg5k#{suffix}.yaml")).result(binding))

    site['clusters'].each { |cluster_uid, cluster|
      data = data = conf[site_uid][cluster_uid]
      if data.nil?
        puts "Warning: configuration not found in #{options[:conf_dir]}/kadeployg5k#{suffix}.yaml for #{cluster_uid}. Skipped"
        next
      end

      output = ERB.new(File.read('templates/kadeployg5k.conf.erb')).result(binding)

      output_file = Pathname("#{options[:output_dir]}/modules/kadeployg5k/files/#{site_uid}/server_conf#{suffix.tr('-', '_')}/#{cluster_uid}-cluster.conf")
      output_file.dirname.mkpath()
      File.write(output_file, output)
      
    }
    
  }
}
