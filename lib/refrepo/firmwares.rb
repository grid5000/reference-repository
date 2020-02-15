require 'refrepo/data_loader'

def nodes_by_model(model)
  nodes = []
  data = load_data_hierarchy
  data['sites'].keys.each do |site|
    data['sites'][site]['clusters'].each do |cluster|
      c = cluster.last
      c['nodes'].each do |_, v|
        nodes << v
      end
    end
  end
  model_filter = nodes.select do |node|
    node['chassis']['name'] =~ /#{model}/
  end
  model_filter
end

def get_firmware_version(devices)
  version = Hash.new
  devices.each do |device|
    if device.has_key?("firmware_version")
      version[device['model']] = device['firmware_version']
    end
  end
  version
end

def gen_firmwares_table
end
