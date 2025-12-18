# frozen_string_literal: true

require 'refrepo/hash/hash'
require 'erb'

def generate_puppet_kwollectg5k(options)
  conf_dir = "#{options[:conf_dir]}/ipmitools".freeze
  kwollect_output_dir = "#{options[:modules_dir]}/grid5000/kwollect".freeze
  wattmetre_output_dir = "#{kwollect_output_dir}-wattmetre".freeze
  puts "Writing kwollect configuration files to: #{options[:output_dir]}"
  puts "Using configuration directory: #{conf_dir}"
  puts "For site(s): #{options[:sites].join(', ')}"

  console_pwd_path = "#{conf_dir}/console-password.yaml".freeze
  if !Pathname(console_pwd_path).exist?
    puts "Warning: No #{console_pwd_path} file found"
    credentials = {}
  else
    credentials = YAML.load_file(console_pwd_path)
  end

  refapi = load_data_hierarchy

  puts "Old configurations directory will be stored in /tmp/kwollect-#{Time.now.to_i}"
  backup_dir = Pathname("/tmp/kwollect-#{Time.now.to_i}/")
  backup_dir.mkpath

  refapi['sites'].each do |site_uid, site|
    next unless options[:sites].include?(site_uid)

    if File.directory?("#{kwollect_output_dir}/#{site_uid}")
      FileUtils.mv("#{kwollect_output_dir}/#{site_uid}", "#{backup_dir}/")
    end

    # Metrics configuration for each node
    site.fetch('clusters', {}).sort.each do |cluster_uid, cluster|
      cluster['nodes'].each_sort_by_node_uid do |node_uid, node|
        ipmi_credentials = credentials.fetch(site_uid, {}).fetch(cluster_uid, '').split(' ')
        ipmi_credentials.map! { |s| ERB::Util.url_encode(s) }
        ipmi_credentials = ipmi_credentials.join(':')

        output = ERB.new(File.read(File.expand_path('templates/kwollect-node.erb', File.dirname(__FILE__))),
                         trim_mode: '-').result(binding)
        output_file = Pathname("#{kwollect_output_dir}/#{site_uid}/#{node_uid}.conf")
        output_file.dirname.mkpath
        File.write(output_file, output)
      end
    end

    # Metrics configuration for network device
    site['network_equipments'].each do |neteq_uid, neteq|
      # do not apply to equipment we do not manage
      next unless neteq['managed_by_us']

      output = ERB.new(File.read(File.expand_path('templates/kwollect-network.erb', File.dirname(__FILE__))),
                       trim_mode: '-').result(binding)
      output_file = Pathname("#{kwollect_output_dir}/#{site_uid}/#{neteq_uid}.conf")
      output_file.dirname.mkpath
      File.write(output_file, output)
    end

    # Metrics configuration for PDU
    ## First, parse all PDU to find nodes that use two PSUs
    ports_by_node = {}
    site.fetch('pdus', {}).each do |pdu_uid, pdu|
      pdu.fetch('metrics', []).each do |metric|
        next unless metric['source']['protocol'].start_with?('snmp')

        next unless metric['source']['id'].include?('%PORT%')

        pdu.fetch('ports', {}).each do |port_uid, node_uid|
          ports_by_node[node_uid] = [] unless ports_by_node.has_key?(node_uid)
          ports_by_node[node_uid] << "#{pdu_uid}-port-#{port_uid}"
          ports_by_node[node_uid].uniq!
        end
      end
    end
    ## Then, write PDU metrics config
    site.fetch('pdus', {}).each do |pdu_uid, pdu|
      output = ERB.new(File.read(File.expand_path('templates/kwollect-pdu.erb', File.dirname(__FILE__))),
                       trim_mode: '-').result(binding)
      output_file = Pathname("#{kwollect_output_dir}/#{site_uid}/#{pdu_uid}.conf")
      output_file.dirname.mkpath
      File.write(output_file, output)
    end

    # Metrics from others devices (sensors, cooling, global wattmetre, ...)
    site.fetch('sensors', {}).each do |sensor_uid, sensor|
      output = ERB.new(File.read(File.expand_path('templates/kwollect-sensors.erb', File.dirname(__FILE__))),
                       trim_mode: '-').result(binding)
      output_file = Pathname("#{kwollect_output_dir}/#{site_uid}/#{sensor_uid}.conf")
      output_file.dirname.mkpath
      File.write(output_file, output)
    end

    # Wattmetre mapping configuration
    wattmetre_port_per_node = {}
    site.fetch('pdus', {}).each do |pdu_uid, pdu|
      next if pdu.fetch('metrics', []).none? { |metric| metric['source']['protocol'] == 'wattmetre' }

      pdu.fetch('ports', {}).each do |port, node|
        wattmetre_port_per_node[node] = [] unless wattmetre_port_per_node.key?(node)
        wattmetre_port_per_node[node] << "#{pdu_uid}-port#{port}"
      end
    end
    next if wattmetre_port_per_node.empty?

    output = ERB.new(File.read(File.expand_path('templates/kwollect-wattmetre-mapping.erb', File.dirname(__FILE__))),
                     trim_mode: '-').result(binding)
    output_file = Pathname("#{wattmetre_output_dir}/#{site_uid}/wattmetre-mapping.conf")
    output_file.dirname.mkpath
    File.write(output_file, output)
  end
end
