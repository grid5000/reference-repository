# This script generates conmang5k/files/<site_uid>/conman.conf from input/, conf/console.yaml and conf/console-password.yaml

require 'refrepo/hash/hash'

# Apply ERB template and save result to file
def write_conman_file(site_uid, site_refapi, site_config, site_credentials, options)
  output = ERB.new(File.read(File.expand_path('templates/conman.erb', File.dirname(__FILE__)))).result(binding)

  output_file = Pathname("#{options[:output_dir]}/platforms/production/modules/generated/files/conman/server/#{site_uid}.conf")

  output_file.dirname.mkpath()
  File.write(output_file, output)
end

def generate_puppet_conmang5k(options)
  if not options[:conf_dir]
    options[:conf_dir] = "#{options[:output_dir]}/platforms/production/generators/ipmitools/"
  end

  raise("Error: #{options[:conf_dir]} does not exist. The given configuration path is incorrect") unless Pathname(options[:conf_dir].to_s).exist?

  puts "Writing Conman configuration files to: #{options[:output_dir]}"
  puts "Using configuration directory: #{options[:conf_dir]}"
  puts "For site(s): #{options[:sites].join(', ')}"

  refapi = load_data_hierarchy

  config      = YAML::load_file(options[:conf_dir] + 'console.yaml')
  credentials = YAML::load_file(options[:conf_dir] + 'console-password.yaml')


  # Loop over each site
  refapi["sites"].each { |site_uid, site_refapi|

    next unless options[:sites].include?(site_uid)

    write_conman_file(site_uid, site_refapi, config[site_uid], credentials[site_uid], options)
  }
end
