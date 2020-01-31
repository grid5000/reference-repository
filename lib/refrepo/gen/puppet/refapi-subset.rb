# coding: utf-8

require 'refrepo/data_loader'

def generate_puppet_refapi_subset(options)
  if not options[:conf_dir]
    options[:conf_dir] = "#{options[:output_dir]}/platforms/production/generators/refapi"
  end

  options[:sites].each do |site|
    output_file = "#{options[:output_dir]}/platforms/production/modules/generated/files/grid5000/refapi/#{site}.json"
    gen_json(site, output_file)
  end
end

# For now, we only put software key in the generated JSON
def gen_json(site, output_path)
  site_data_hierarchy = load_data_hierarchy
  site_data_hierarchy.delete_if { |key| key != 'sites' }
  site_data_hierarchy['sites'].delete_if { |key| key != site }
  site_data_hierarchy['sites'][site].delete_if { |key| key != 'clusters' }
  site_data_hierarchy['sites'][site]['clusters'].to_h.each do |cluster_uid, cluster_hash|
    cluster_hash.delete_if { |key| key != 'nodes' }
    cluster_hash['nodes'].to_h.each do |node_uid, node_hash|
      node_hash.delete_if { |key| key != 'software' }
    end
  end

  output_file = File.new(output_path, 'w')
  output_file.write(JSON.pretty_generate(site_data_hierarchy))
end
