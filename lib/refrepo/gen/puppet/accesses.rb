# frozen_string_literal: true

# For now, list MC/Bidules gga
BIDULE_GGA = %w[cidre linkmedia intuidoc lacodam sirocco wide].freeze

require 'refrepo/data_loader'

def generate_puppet_accesses(options)
  accesses = {}
  all_nodesets.each do |nodeset|
    accesses[nodeset] = {}
    all_ggas.each do |gga|
      acc = if nodeset == gga || nodeset == 'common'
              'PRIO'
            else
              'BEST'
            end
      accesses[nodeset][gga] = acc
    end
  end
  options[:sites].each do |_site|
    output_file = "#{options[:output_dir]}/platforms/production/modules/generated/files/grid5000/accesses/accesses.yaml"
    generate_accesses_yaml(output_file, accesses)
  end
end

def all_ggas
  groups = RefRepo::Utils.get_api('users/groups?is_gga=true')['items'].map { |x| x['name'] }
  groups.select { |x| BIDULE_GGA.include?(x) }
end

def all_nodesets
  nodeset = []
  site_data_hierarchy = load_data_hierarchy
  site_data_hierarchy['sites'].each_key do |site|
    site_data_hierarchy['sites'][site].fetch('clusters', {}).each_key do |cluster|
      site_data_hierarchy['sites'][site][cluster]
      nodeset += site_data_hierarchy['sites'][site]['clusters'][cluster]['nodes'].map { |_, v| v['nodeset'] }
    end
  end
  nodeset.uniq
end

def generate_accesses_yaml(output_path, data)
  output_file = File.new(output_path, 'w')
  output_file.write(YAML.dump(data))
end
