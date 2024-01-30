# coding: utf-8

require 'refrepo/data_loader'
require 'refrepo/gpu_ref'

def get_sub_simplifier_default_aliases(options)
  if not options[:conf_dir]
    options[:conf_dir] = "#{options[:output_dir]}/platforms/production/generators/sub-simplifier"
  end

  raise("Error: file #{options[:conf_dir]}/aliases.yaml does not exist. The given configuration path is incorrect") unless Pathname("#{options[:conf_dir]}/aliases.yaml").exist?

  default_aliases = YAML.load(File.read("#{options[:conf_dir]}/aliases.yaml"))

  gpu_aliases = GPURef.get_all_aliases.map do |al, model|
    [al, {'value' => "gpu_model='#{model}'",
          'desc' => "Select node(s) with #{model} GPU",
          'category' => 'GPUs'}]
  end.to_h
  default_aliases.merge!(gpu_aliases)

  gpu_mem_aliases = [6, 12, 16, 24, 32, 40, 60].map{|m| ["gpu-#{m}GB", {'value' => "gpu_mem>=#{m*1000}", 'category': 'GPUS',
    'desc' => "Select node(s) with GPU having more than #{m}GB of memory"}]}.to_h
  default_aliases.merge!(gpu_mem_aliases)

  mem_aliases = {}
  mem_multipliers = [24, 32]
  mem_multipliers.each do |i|
    while i <= 1024 do
      mem_aliases["#{i}GB"] = {}
      mem_aliases["#{i}GB"]['value'] = "memnode>=#{i*1024}"
      mem_aliases["#{i}GB"]['category'] = 'Memory'
      mem_aliases["#{i}GB"]['desc'] = "Select node(s) with #{i}GB RAM or more"
      i *= 2
    end
  end
  mem_aliases = mem_aliases.sort_by { |key, _| key.scan(/\d+/).first.to_i }.to_h
  default_aliases.merge!(mem_aliases)

  default_aliases
end

def generate_puppet_oarsub_simplifier_aliases(options)
  default_aliases = get_sub_simplifier_default_aliases(options)
  sites_aliases = generate_all_sites_aliases

  options[:sites].each do |site|
    output_file = "#{options[:output_dir]}/platforms/production/modules/generated/files/grid5000/oar-sub-simplifier/#{site}-aliases.yaml"
    generate_site_aliases_yaml(output_file, default_aliases, sites_aliases[site])
  end
end

def generate_all_sites_aliases
  aliases = {}
  site_data_hierarchy = load_data_hierarchy
  site_data_hierarchy['sites'].each_key do |site|
    aliases[site] = {}
    site_data_hierarchy['sites'][site].fetch('clusters', {}).each_key do |cluster|
      aliases[site][cluster] = "cluster='#{cluster}'"
      aliases[site]["#{cluster}-%d"] = "host='#{cluster}-%d.#{site}.grid5000.fr'"
    end
    aliases[site] = aliases[site].sort_by { |site_name, _| site_name }.to_h
  end

  aliases = aliases.sort_by { |site, _| site }.to_h

  aliases
end

def generate_site_aliases_yaml(output_path, default_aliases, site_aliases)
  aliases = {}
  aliases.merge!(default_aliases.map { |al, tr| [al, tr['value']] }.to_h)
  aliases.merge!(site_aliases)

  output_file = File.new(output_path, 'w')
  output_file.write(YAML.dump(aliases))
end
