# coding: utf-8

require 'refrepo/data_loader'
require 'refrepo/gpu_ref'

def get_sub_simplifier_default_aliases(options)
  if not options[:conf_dir]
    options[:conf_dir] = "#{options[:output_dir]}/platforms/production/generators/sub-simplifier"
  end

  raise("Error: file #{options[:conf_dir]}/aliases.yaml does not exist. The given configuration path is incorrect") unless Pathname("#{options[:conf_dir]}/aliases.yaml").exist?

  default_aliases = YAML.load(File.read("#{options[:conf_dir]}/aliases.yaml"))
  default_aliases.merge!(GPURef.get_all_aliases.transform_values { |value| "gpu_model='#{value}'" })
  mem_multipliers = [24, 32]
  mem_multipliers.each do |i|
    while i <= 1024 do
      default_aliases["#{i}GB"] = "memnode>=#{i*1024}"
      i *= 2
    end
  end

  default_aliases
end

def generate_puppet_oarsub_simplifier_aliases(options)
  default_aliases = get_sub_simplifier_default_aliases(options)

  options[:sites].each do |site|
    output_file = "#{options[:output_dir]}/platforms/production/modules/generated/files/grid5000/oar-sub-simplifier/#{site}-aliases.yaml"
    gen_aliases_yaml(site, output_file, default_aliases)
  end
end

def gen_aliases_yaml(site, output_path, default_aliases)
  aliases = {}
  aliases.merge!(default_aliases)

  site_data_hierarchy = load_data_hierarchy
  site_data_hierarchy['sites'][site]['clusters'].each_key do |cluster|
    aliases[cluster] = "cluster='#{cluster}'"
    aliases["#{cluster}-%d"] = "host='#{cluster}-%d.#{site}.grid5000.fr'"
  end

  output_file = File.new(output_path, 'w')
  output_file.write(YAML.dump(aliases))
end
