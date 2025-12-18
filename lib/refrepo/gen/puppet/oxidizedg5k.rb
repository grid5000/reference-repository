# frozen_string_literal: true

require 'refrepo'

def generate_puppet_oxidizedg5k(options)
  conf_file = "#{options[:conf_dir]}/oxidized/oxidizedg5k.yaml".freeze
  output_dir = "#{options[:modules_dir]}/grid5000/oxidized".freeze
  output_file = "#{output_dir}/oxidized.db".freeze

  puts "Using configuration file: #{conf_file}"
  puts "Writing oxidized database to: #{output_file}"
  if options[:sites] != RefRepo::Utils.get_sites
    puts 'WARNING : Sites options is specified but has no impact on generated files (one file generated for all sites)'
  end

  conf = YAML.load(File.read(conf_file))
  if !conf
    warn "No generator configuration for oxidized found in #{conf_file}, skipping oxidized"
  else
    config_lines = generate_config_lines(conf)
    output = ERB.new(File.read(File.expand_path('templates/oxidized.db.erb', File.dirname(__FILE__))),
                     trim_mode: '-').result(binding)
    mkdir_p(output_dir, verbose: false)
    File.write(output_file, output)
  end
end

def generate_config_lines(conf)
  lines = []
  conf.each do |site, groups|
    groups.each do |group, devices|
      devices.each do |device, values|
        missing_info = %w[driver user password] - values.keys
        if missing_info.length != 0
          puts "Skipping #{device}.#{site}, missing #{missing_info}"
          next
        else
          lines << build_line(site, group, device, values)
        end
      end
    end
  end
  lines
end

def build_line(site, group, device, hash)
  name = device + '.' + site
  group_name = site + '-' + group
  enable = hash.has_key?('enable') ? hash['enable'] : false
  config = [name, group_name, hash['driver'], hash['user'], hash['password'], enable]
  config << hash['ssh_kex'] if hash.has_key?('ssh_kex')
  config.join(':')
end
