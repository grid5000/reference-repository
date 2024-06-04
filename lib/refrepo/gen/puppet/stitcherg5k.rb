
VLANS_FILE = "input/grid5000/vlans.yaml"

PLATFORM = "platforms/production"
HIERA_STITCHER_TEMPLATE = "#{PLATFORM}/generators/stitcher/stitcher.yaml"
HIERA_STITCHER_OUTPUT_PATH = "#{PLATFORM}/modules/generated/files/grid5000/stitcher/stitcher.yml"

STITCHER_MODES = ['production', 'development', 'test']

# main method
def generate_puppet_stitcherg5k(options)
  $options = options
  output_file_path = "#{$options[:output_dir]}/#{HIERA_STITCHER_OUTPUT_PATH}"
  puts "Writing stitcher configuration in #{output_file_path}"
  output = File.new(output_file_path, "w+")
  refapi = load_data_hierarchy

  base_config = YAML.load_file("#{$options[:output_dir]}/#{HIERA_STITCHER_TEMPLATE}")
  sorted_kavlans = Hash.new

  # Ruby sorting dark magic happening below:
  #   The goal is to order the vlans entries by vlan id to have an easy to read conf file.
  #   Since ruby hashes enumerate their values in the order
  #   that the corresponding keys were inserted, we sort the
  #   vlan keys and reinsert them back with their values in a
  #   new hash that is de facto sorted.
  build_stitcher_kavlans_hash(refapi)
    .sort_by {|key, _value| key}
    .each {|a| sorted_kavlans[a[0]] = a[1]}

  output_hash = merge_config(base_config, sorted_kavlans)
  output.write("# MANAGED BY PUPPET\n")
  output.write(output_hash.to_yaml)
end

def build_stitcher_kavlans_hash(refapi)
  stitcher_kavlans_hash = {}
  refapi['sites'].each do |name, site_hash|
    next if not site_hash['kavlans'] # skip sites without kavlan
    global_kavlan = site_hash['kavlans'].select { | id, _hash | id =~ /\d\d/ }.first
    global_kavlan_id = global_kavlan.first.to_i
    stitcher_kavlans_hash[global_kavlan_id] = {"vlan" => 700 + global_kavlan_id, "site" => name}
  end
  return stitcher_kavlans_hash
end

def merge_config(base_config, kavlans)
  output_hash = {}
  STITCHER_MODES.each do |mode|
    output_hash[mode] = {'kavlans' => kavlans}
    base_config.each do |key, value|
      output_hash[mode][key] = value
    end
  end
  return output_hash
end
