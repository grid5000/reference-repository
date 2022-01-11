# coding: utf-8

require 'refrepo/data_loader'

def generate_puppet_kavlanngg5k(options)
  gen_json("#{options[:output_dir]}/platforms/production/modules/generated/files/grid5000/kavlanng/g5k.json")
end

def gen_json(output_path)
  site_data_hierarchy = load_data_hierarchy

  site_data_hierarchy.delete_if { |k| k != 'sites' }
  site_data_hierarchy['sites'].each do |site_id, site_h|
    puts site_id
    site_h.delete_if { |k| !['clusters', 'network_equipments'].include? k }
    site_h['clusters'].each do |cluster_id, cluster_h|
      puts '  ' + cluster_id
      cluster_h.delete_if { |k| k != 'nodes' }
      cluster_h['nodes'].each do |node_id, node_h|
        node_h.delete_if { |k| k != 'network_adapters' }
      end
    end
    site_h['network_equipments'].delete_if { |k, v| v['kind'] != 'router' }
    routers = site_h['network_equipments'].keys
    if routers.length != 1
      puts "ERROR: #{site_id} has #{routers.length} routers"
    end
    gw = routers[0]
    puts "  #{site_id} gw: #{gw}"
    site_h['network_equipments'][gw].delete_if { |k| ! ['ip', 'ip6', 'kind'].include? k }
  end
  output_file = File.new(output_path, 'w')
  output_file.write(JSON.pretty_generate(site_data_hierarchy))
end
