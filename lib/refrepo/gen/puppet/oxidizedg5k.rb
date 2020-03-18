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
    output = ERB.new(File.read(File.expand_path('templates/oxidized.db.erb', File.dirname(__FILE__))), nil, '-').result(binding)
    output_file = Pathname("#{options[:output_dir]}//platforms/production/modules/generated/files/grid5000/oxidized/oxidized.db")
    output_file.dirname.mkpath()
    File.write(output_file, output)
  end

end
