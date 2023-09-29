
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
  global_kavlans_hash = build_stitcher_kavlans_hash(refapi)
  output_hash = merge_config(base_config, global_kavlans_hash)
  output.write(output_hash.to_yaml)
end

def build_stitcher_kavlans_hash(refapi)
  stitcher_kavlans_hash = {}
  refapi['sites'].each do |name, site_hash|
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
