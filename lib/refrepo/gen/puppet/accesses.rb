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
  generate_accesses_yaml(File.join(output_file_path, 'human_readable_accesses_by_gga.yaml'), filtered_access_level)
  by_nodeset_hash = Hash.new { |hash, key| hash[key] = {} }
  filtered_access_level.each do |outer_key, inner_hash|
    inner_hash.each do |inner_key, value|
      by_nodeset_hash[inner_key][outer_key] = value
    end
  end
  generate_accesses_yaml(File.join(output_file_path, 'human_readable_accesses_by_nodeset.yaml'), by_nodeset_hash)

  filtered_access_level_list = []
  filtered_access_level.each_pair do |gga, v1|
    v1.each_pair do |nodeset, v2|
      filtered_access_level_list << { 'gga' => gga, 'nodeset' => nodeset }.merge(v2)
    end
  end
  File.write(File.join(output_file_path, 'accesses_by_nodeset.txt'),
                  filtered_access_level_list.sort_by { |e| [e['nodeset'], e['gga']] }.
                      map { |e| sprintf("%-13s %-25s %-11s %2d", *e.values_at('nodeset', 'gga', 'label', 'level')) }.join("\n"))
  File.write(File.join(output_file_path, 'accesses_by_gga.txt'),
                  filtered_access_level_list.sort_by { |e| [e['gga'], e['nodeset']] }.
                      map { |e| sprintf("%-13s %-25s %-11s %2d", *e.values_at('nodeset', 'gga', 'label', 'level')) }.join("\n"))


end
