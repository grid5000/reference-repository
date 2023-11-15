require 'refrepo'

def generate_puppet_oxidizedg5k(options)

  if not options[:conf_dir]
    options[:conf_dir] = "#{options[:output_dir]}/platforms/production/generators/oxidized"
  end

  raise("Error: #{options[:conf_dir]} does not exist. The given configuration path is incorrect") unless Pathname(options[:conf_dir].to_s).exist?

  puts "Writing oxidized database to: #{options[:output_dir]}/platforms/production/modules/generated/files/grid5000/oxidized/oxidized.db"
  puts "Using configuration directory: #{options[:conf_dir]}"
  if options[:sites] != RefRepo::Utils::get_sites
    puts "WARNING : Sites options is specified but has no impact on generated files (one file generated for all sites)"
  end

  conf = YAML::load(File.read("#{options[:conf_dir]}/oxidizedg5k.yaml"))
  if not conf
    warn "No generator configuration for oxidized found in #{options[:conf_dir]}/oxidizedg5k.yaml, skipping oxidized"
  else
    config_lines = generate_config_lines(conf)
    output = ERB.new(File.read(File.expand_path('templates/oxidized.db.erb', File.dirname(__FILE__))), trim_mode: '-').result(binding)
    output_file = Pathname("#{options[:output_dir]}//platforms/production/modules/generated/files/grid5000/oxidized/oxidized.db")
    output_file.dirname.mkpath()
    File.write(output_file, output)
  end
end

def generate_config_lines(conf)
  lines = []
  conf.each do |site, groups|
    groups.each do |group,devices|
      devices.each do |device,values|
        missing_info = ["driver","user","password"] - values.keys
        if missing_info.length != 0
          puts "Skipping #{device}.#{site}, missing #{missing_info}"
          next
        else
          lines << build_line(site, group, device, values)
        end
      end
    end
  end
  return lines
end

def build_line(site, group, device, hash)
  name = device + '.' + site
  group_name = site + '-' + group
  enable = hash.has_key?('enable') ? hash['enable'] : false
  config = [name, group_name, hash['driver'], hash['user'], hash['password'], enable]
  if hash.has_key?('ssh_kex')
    config << hash['ssh_kex']
  end
  return config.join(':')
end
