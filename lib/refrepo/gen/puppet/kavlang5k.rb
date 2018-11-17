# !!! Require to "gem install ruby-ip", do not install "ip" gem !!!

require 'refrepo/hash/hash'

def generate_puppet_kavlang5k(options)

  if not options[:conf_dir]
    options[:conf_dir] = "#{options[:output_dir]}/platforms/production/generators/kavlan"
  end

  raise("Error: #{options[:conf_dir]} does not exist. The given configuration path is incorrect") unless Pathname(options[:conf_dir].to_s).exist?

  puts "Writing kavlan configuration files to: #{options[:output_dir]}"
  puts "Using configuration directory: #{options[:conf_dir]}"
  puts "For site(s): #{options[:sites].join(', ')}"

  refapi = load_yaml_file_hierarchy

  refapi['sites'].each { |site_uid, site_refapi|

    next unless options[:sites].include?(site_uid)

    conf = YAML::load(ERB.new(File.read("#{options[:conf_dir]}/kavlang5k.yaml"), nil, '-').result(binding))[site_uid]
    if not conf
      warn "No generator configuration for site #{site_uid} found in #{options[:conf_dir]}/kavlang5k.yaml, skipping kavlan.conf"
    else
      output = ERB.new(File.read(File.expand_path('templates/kavlan.conf.erb', File.dirname(__FILE__))), nil, '-').result(binding)
      output_file = Pathname("#{options[:output_dir]}//platforms/production/modules/generated/files/grid5000/kavlan/#{site_uid}/kavlan.conf")
      output_file.dirname.mkpath()
      File.write(output_file, output)
    end

    output = ERB.new(File.read(File.expand_path('templates/kavlan-cluster.conf.erb', File.dirname(__FILE__))), nil, '-').result(binding)
    output_file = Pathname("#{options[:output_dir]}//platforms/production/modules/generated/files/grid5000/kavlan/#{site_uid}/#{site_uid}.conf")
    output_file.dirname.mkpath()
    File.write(output_file, output)

    (1..9).each do |kavlan_id|
      output = ERB.new(File.read(File.expand_path('templates/kavlan-dhcp.conf.erb', File.dirname(__FILE__))), nil, '-').result(binding)
      output_file = Pathname("#{options[:output_dir]}//platforms/production/modules/generated/files/grid5000/kavlan/#{site_uid}/dhcp/dhcpd-#{kavlan_id}.conf")
      output_file.dirname.mkpath()
      File.write(output_file, output)
    end

    # Look for site's global kavlan
    kavlan_id = refapi['sites'][site_uid]['kavlans'].each_key.select {|k| k.is_a?(Numeric) and k>9}.pop()
    output = ERB.new(File.read(File.expand_path('templates/kavlan-dhcp.conf.erb', File.dirname(__FILE__))), nil, '-').result(binding)
    output_file = Pathname("#{options[:output_dir]}//platforms/production/modules/generated/files/grid5000/kavlan/#{site_uid}/dhcp/dhcpd-0.conf")
    File.write(output_file, output)

  }
end
