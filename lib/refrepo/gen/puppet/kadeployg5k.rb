# frozen_string_literal: true

require 'refrepo/hash/hash'

# Compute cluster prefix
# input: cluster_list = ['graoully', 'graphene', 'griffon', ...]
# output: prefix_hash = {'grao' => 'graoully', 'graphe' => 'graphene', ...}
def cluster_prefix(cluster_list)
  # Shrink cluster names. Start with 3 characters
  # prefix_hash = {'gra' => ['graoully', 'graphene', ...], 'gri' => ['griffon']}
  prefix_hash = cluster_list.group_by { |x| x[0, 3] }

  # Add characters until each prefix is unique
  loop do
    prefix_hash.clone.each do |k, v|
      next if v.size == 1

      r = v.group_by { |x| x[0, k.length + 1] }
      prefix_hash.delete(k)
      prefix_hash.merge!(r)
    end
    break if prefix_hash.keys.size == cluster_list.size # no prefix duplicates
  end

  # Inverse key <=> value
  prefix_hash = Hash[prefix_hash.map { |k, v| [v[0], k] }]
end

# Extract the node ip from the node hash
def get_ip(node)
  node['network_adapters'].select do |n|
    n['mounted'] && n['device'] =~ /eth/
  end[0]['ip']
end

def generate_puppet_kadeployg5k(options)
  global_hash = load_data_hierarchy

  conf_dir = "#{options[:conf_dir]}/kadeploy".freeze
  output_dir = "#{options[:output_dir]}/platforms/production/modules/generated/files/grid5000/kadeploy/".freeze
  verbose = options.fetch('verbose', false)

  raise("Error: #{conf_dir} does not exist. The given configuration path is incorrect") unless Pathname(conf_dir).exist?

  puts "Writing Kadeploy configuration files to: #{options[:output_dir]}"
  puts "Using configuration directory: #{conf_dir}"
  puts "For site(s): #{options[:sites].join(', ')}"

  kadeploy_generator = "#{conf_dir}/kadeployg5k.yaml".freeze
  kadeploy_output_dir = "#{output_dir}/server".freeze
  prod_instance = 'kadeploy3'
  generate_clusters_conf(options[:sites], global_hash, kadeploy_generator, kadeploy_output_dir, prod_instance, verbose)
  generate_global_config(options[:sites], global_hash, kadeploy_output_dir, prod_instance)

  kadeploy_dev_generator = "#{conf_dir}/kadeployg5k-dev.yaml".freeze
  kadeploy_dev_output_dir = "#{output_dir}/server_dev/".freeze
  dev_instance = 'kadeploy3-dev'
  generate_clusters_conf(options[:sites], global_hash, kadeploy_dev_generator, kadeploy_dev_output_dir, dev_instance, verbose)
  generate_global_config(options[:sites], global_hash, kadeploy_dev_output_dir, dev_instance)
end

def generate_clusters_conf(sites, global_hash, generator_path, output_dir, instance, verbose)
  sites.each do |site_uid|
    site = global_hash['sites'][site_uid]

    #
    # Generate <cluster_uid>-cluster.conf files
    #

    # Load 'conf/kadeployg5k.yaml' data and fill up the kadeployg5k.conf.erb template for each cluster

    conf = YAML.load(ERB.new(File.read(generator_path)).result(binding))

    clusters_conf = { 'clusters' => [] } # output clusters.conf
    clusters = site.fetch('clusters', {})
    prefix = cluster_prefix(clusters.keys)

    # site['clusters'].each
    clusters.sort.each do |cluster_uid, cluster|
      defaults = conf['defaults']
      overrides = conf[site_uid][cluster_uid]

      if overrides.nil? && %w[defaut abaca production].none? { |q| cluster['queues'].include?(q) }
        puts "Warning: #{cluster_uid} has no kadeployg5k#{suffix} config, and isn't in default or abaca queue."
        puts "Warning: Skipping #{cluster_uid} configuration."
        next
      elsif overrides.nil?
        puts "ERROR: #{cluster_uid} has no kadeployg5k#{suffix} config (and is not in queue testing)"
        exit(1)
      end

      dupes = (defaults.to_a & overrides.to_a)
      key_dupes = (defaults.to_a.map(&:first) & overrides.to_a.map(&:first))
      puts "Warning: Overriding default values #{dupes} by the same value for #{cluster_uid}" unless dupes.empty?
      if !key_dupes.empty? && verbose
        puts "Info: cluster-specific configuration for #{cluster_uid} overrides default values: #{key_dupes}"
      end
      data = defaults.merge(overrides)
      if data.nil?
        puts "Warning: configuration not found in #{conf_dir}/kadeployg5k#{suffix}.yaml for #{cluster_uid}. Skipped"
        next
      end

      output = ERB.new(File.read(File.expand_path('templates/kadeployg5k.conf.erb', File.dirname(__FILE__))),
                       trim_mode: '-').result(binding)

      output_file = Pathname("#{output_dir}/#{site_uid}/#{cluster_uid}-cluster.conf")

      output_file.dirname.mkpath
      File.write(output_file, output)
    end
  end
end

def generate_global_config(sites, global_hash, output_dir, instance)
  sites.each do |site_uid|
    site = global_hash['sites'][site_uid]

    clusters_conf = { 'clusters' => [] } # output clusters.conf
    clusters = site.fetch('clusters', {})
    prefix = cluster_prefix(clusters.keys)

    clusters.sort.each do |cluster_uid, cluster|
      cluster_conf = {}
      cluster_conf['name']      = cluster_uid
      cluster_conf['prefix']    = prefix[cluster_uid]
      cluster_conf['conf_file'] = "/etc/#{instance}/#{cluster_uid}-cluster.conf"
      cluster_conf['nodes']     = []

      # init
      first = last = c_uid = -1
      first_ip = ['0', '0', '0', 0]

      # group nodes by range (griffon-[1-92] -> 172.16.65.[1-92])
      cluster['nodes'].each_sort_by_node_uid do |node_uid, node|
        next if node.nil? || (node['status'] && node['status'] == 'retired')

        c = node_uid.to_s.split(/-/).first
        id = node_uid.to_s.split(/-/)[1]
        id = id.to_i
        ip = get_ip(node).split('.')
        ip[3] = ip[3].to_i

        if c == c_uid && id == last + 1 && ip[0..2] == first_ip[0..2] && ip[3] == first_ip[3] + id - first
          # extend range
          last = id
        else
          if c_uid != -1
            node = {}
            node['name']    = "#{c_uid}-[#{first}-#{last}].#{site_uid}.grid5000.fr"
            node['address'] = "#{first_ip[0..2].join('.')}.[#{first_ip[3]}-#{first_ip[3] + last - first}]"
            cluster_conf['nodes'] << node
          end

          # new range
          first = last = id
          first_ip = ip
          c_uid = c
        end
      end
      # last range
      if c_uid != -1
        node = {}
        node['name']    = "#{c_uid}-[#{first}-#{last}].#{site_uid}.grid5000.fr"
        node['address'] = "#{first_ip[0..2].join('.')}.[#{first_ip[3]}-#{first_ip[3] + last - first}]"
        cluster_conf['nodes'] << node
      end

      clusters_conf['clusters'] << cluster_conf
    end

    output_file = Pathname("#{output_dir}/#{site_uid}/clusters.conf")

    output_file.dirname.mkpath
    write_yaml(output_file, clusters_conf)
    add_header(output_file)
  end
end
