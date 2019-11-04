# Load a hierarchy of JSON file into a Ruby hash

require 'refrepo/hash/hash'

def load_data_hierarchy

  global_hash = {} # the global data structure

  directory = File.expand_path("../../data/grid5000/", File.dirname(__FILE__))
  Dir.chdir(directory) do

    # Recursively list the .yaml files.
    # The order in which the results are returned depends on the system (http://ruby-doc.org/core-2.2.3/Dir.html).
    # => List deepest files first as they have lowest priority when hash keys are duplicated.
    list_of_files = Dir['**/*.json'].sort_by { |x| -x.count('/') }

    list_of_files.each do |filename|
      # Load JSON
      file_hash = JSON::parse(IO::read(filename))

      # Inject the file content into the global_hash, at the right place
      path_hierarchy = File.dirname(filename).split('/')     # Split the file path (path relative to input/)
      path_hierarchy = [] if path_hierarchy == ['.']

      if ['nodes', 'network_equipments', 'servers', 'pdus'].include?(path_hierarchy.last)
        # it's a node or a network_equipment, add the uid
        path_hierarchy << file_hash['uid']
      end
      file_hash = Hash.from_array(path_hierarchy, file_hash) # Build the nested hash hierarchy according to the file path
      global_hash = global_hash.deep_merge(file_hash)        # Merge global_hash and file_hash. The value for entries with duplicate keys will be that of file_hash

      # Expand the hash. Done at each iteration for enforcing priorities between duplicate entries:
      # ie. keys to be expanded have lowest priority on existing entries but higher priority on the entries found in the next files
      global_hash.expand_square_brackets(file_hash)

    end

  end

  return global_hash
end

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
