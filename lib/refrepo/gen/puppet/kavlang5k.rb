# frozen_string_literal: true

require 'refrepo/hash/hash'

def kavlan_switch_port_lookup(switch, node_uid, interface = '')
  switch['linecards'].each_with_index do |lc, lc_uid|
    next unless lc['ports']

    lc['ports'].each_with_index do |port, port_uid|
      pattern_source = lc
      if port.is_a?(Hash)
        switch_remote_port = port['port'] || lc['port'] || ''
        switch_remote_uid = port['uid']
        pattern_source = port if port.has_key?('snmp_pattern') or port.has_key?('kavlan_pattern')
      else
        switch_remote_port = lc['port'] || ''
        switch_remote_uid = port
      end
      # warn "#{node_uid}, #{switch_uid}, #{lc_uid}, #{port_uid}, #{switch_remote_uid}, #{switch_remote_port}, #{interface}"
      next unless switch_remote_uid == node_uid and switch_remote_port == interface

      # Build port name from snmp_naming_pattern
      # Example: '3 2 GigabitEthernet%LINECARD%/%PORT%' -> 'GigabitEthernet3/2'
      pattern = pattern_source.has_key?('kavlan_pattern') ? pattern_source['kavlan_pattern'] : pattern_source['snmp_pattern']
      port_name = pattern.sub('%LINECARD%', lc_uid.to_s).sub('%PORT%', port_uid.to_s)
      return port_name
    end
  end
  nil
end

def generate_puppet_kavlang5k(options)
  conf_dir = "#{options[:conf_dir]}/kavlan".freeze

  unless Pathname(conf_dir.to_s).exist?
    raise("Error: #{conf_dir} does not exist. The given configuration path is incorrect")
  end

  puts "Writing kavlan configuration files to: #{options[:output_dir]}"
  puts "Using configuration directory: #{conf_dir}"
  puts "For site(s): #{options[:sites].join(', ')}"

  refapi = load_data_hierarchy

  refapi['sites'].each do |site_uid, site_refapi|
    next unless options[:sites].include?(site_uid)

    conf = YAML.load(ERB.new(File.read("#{conf_dir}/kavlang5k.yaml"),
                             trim_mode: '-').result(binding))[site_uid]
    if !conf
      warn "No generator configuration for site #{site_uid} found in #{conf_dir}/kavlang5k.yaml, skipping kavlan.conf"
    else
      output = ERB.new(File.read(File.expand_path('templates/kavlan.conf.erb', File.dirname(__FILE__))),
                       trim_mode: '-').result(binding)
      output_file = Pathname("#{options[:output_dir]}//platforms/production/modules/generated/files/grid5000/kavlan/#{site_uid}/kavlan.conf")
      output_file.dirname.mkpath
      File.write(output_file, output)
    end

    output = ERB.new(File.read(File.expand_path('templates/kavlan-cluster.conf.erb', File.dirname(__FILE__))),
                     trim_mode: '-').result(binding)
    output_file = Pathname("#{options[:output_dir]}//platforms/production/modules/generated/files/grid5000/kavlan/#{site_uid}/#{site_uid}.conf")
    output_file.dirname.mkpath
    File.write(output_file, output)

    (1..9).each do |kavlan_id|
      %w[dhcpd dhcpd6].each do |dhcpkind|
        output = ERB.new(File.read(File.expand_path('templates/kavlan-dhcp.conf.erb', File.dirname(__FILE__))),
                         trim_mode: '-').result(binding)
        output_file = Pathname("#{options[:output_dir]}//platforms/production/modules/generated/files/grid5000/kavlan/#{site_uid}/dhcp/#{dhcpkind}-#{kavlan_id}.conf")
        output_file.dirname.mkpath
        File.write(output_file, output)
      end
    end

    # Look for site's global kavlan
    # TODO fix dirty convertion to_i below
    kavlan_id = refapi['sites'][site_uid]['kavlans'].each_key.select { |k| k.to_i > 9 }.pop.to_i
    %w[dhcpd dhcpd6].each do |dhcpkind|
      output = ERB.new(File.read(File.expand_path('templates/kavlan-dhcp.conf.erb', File.dirname(__FILE__))),
                       trim_mode: '-').result(binding)
      output_file = Pathname("#{options[:output_dir]}//platforms/production/modules/generated/files/grid5000/kavlan/#{site_uid}/dhcp/#{dhcpkind}-0.conf")
      File.write(output_file, output)
    end
  end
end
