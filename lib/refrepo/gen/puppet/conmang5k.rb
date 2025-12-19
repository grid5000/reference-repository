# frozen_string_literal: true

# This script generates conmang5k/files/<site_uid>/conman.conf from input/, conf/console.yaml and conf/console-password.yaml

require 'refrepo/hash/hash'

# Apply ERB template and save result to file
def write_conman_file(site_uid, site_refapi, site_config, site_credentials, options)
  output = ERB.new(File.read(File.expand_path('templates/conman.erb', File.dirname(__FILE__)))).result(binding)

  output_file = Pathname("#{options[:modules_dir]}/conman/server/#{site_uid}.conf")

  output_file.dirname.mkpath
  File.write(output_file, output)
end

def generate_puppet_conmang5k(options)
  config_dir = "#{options[:conf_dir]}/ipmitools".freeze

  unless Pathname(config_dir).exist?
    raise("Error: #{config_dir} does not exist. The given configuration path is incorrect")
  end

  puts "Writing Conman configuration files to: #{options[:output_dir]}"
  puts "Using configuration directory: #{config_dir}"
  puts "For site(s): #{options[:sites].join(', ')}"

  refapi = load_data_hierarchy

  config      = YAML.load_file("#{config_dir}/console.yaml")
  credentials = YAML.load_file("#{config_dir}/console-password.yaml")

  # Loop over each site
  refapi['sites'].each do |site_uid, site_refapi|
    next unless options[:sites].include?(site_uid)

    unless config.has_key?(site_uid)
      RefRepo::Utils.warn_or_abort_partial_site("Warning: no information about #{site_uid} to generate conman configuration.")
      next
    end

    write_conman_file(site_uid, site_refapi, config[site_uid], credentials[site_uid], options)
  end
end
