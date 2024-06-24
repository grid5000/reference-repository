# frozen_string_literal: true

require 'refrepo/accesses'

# generate nodeset mode history and access level
def generate_puppet_accesses(options)
  access_mode_history = generate_nodeset_mode_history
  access_level = generate_access_level

  output_file_path = "#{options[:output_dir]}/platforms/production/modules/generated/files/grid5000/accesses/"
  generate_accesses_yaml(File.join(output_file_path, 'accesses_mode_history.yaml'), access_mode_history)
  generate_accesses_json(File.join(output_file_path, 'accesses.json'), access_level)
  # We remove the no access from the yaml who is just here for easier reading (only the JSON is used)
  filtered_access_level = access_level.transform_values do |v|
    v.reject { |_, v2| v2['level'] == -1 }
  end.to_h
  generate_accesses_yaml(File.join(output_file_path, 'accesses.yaml'), filtered_access_level)
end
