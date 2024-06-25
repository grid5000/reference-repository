# frozen_string_literal: true

require 'refrepo/data_loader'
require 'git'

$group_of_gga = {}

ALL_GGAS_AND_SITES = RefRepo::Utils.get_public_api('users/ggas_and_sites')
ALL_GGAS = ALL_GGAS_AND_SITES['ggas']
ALL_SITES = ALL_GGAS_AND_SITES['sites']
INPUT_FOLDER = 'input/grid5000/access'
IGNORE_SITES = %w[strasbourg]

$yaml_load_args = {}
#FIXME We cannot drop ruby 2.7 support until jenkins is on debian 11
$yaml_load_args[:aliases] = true if ::Gem::Version.new(RUBY_VERSION) >= ::Gem::Version.new('3.1.0')


# Ulgy function to order hash since order is different on ruby 2.7 and 3.x
def deep_sort_hash(hash)
  sorted_hash = hash.sort.to_h
  sorted_hash.each do |key, value|
    sorted_hash[key] = deep_sort_hash(value) if value.is_a?(Hash)
  end
  sorted_hash
end



def generate_accesses_yaml(output_path, data)
  output_file = File.new(output_path, 'w')
  output_file.write(deep_sort_hash(data).to_yaml)
end

def generate_accesses_json(output_path, data)
  output_file = File.new(output_path, 'w')
  output_file.write(JSON.pretty_generate(deep_sort_hash(data)))
end

##########################################
#   nodeset mode history generation      #
##########################################

# calculate the prio of the node
# if only p1 is defined, the node is exclusive
def prio_mode(prio)
  return 'undefined' if prio.nil? || prio.values.flatten.empty?

  keys_to_check = prio.keys - ['besteffort']
  only_p1_filled = keys_to_check.all? do |key|
    if key == 'p1'
      !prio[key].nil? && !prio[key].empty?
    else
      prio[key].nil? || prio[key].empty?
    end
  end
  if only_p1_filled
    "exclusive #{prio['p1'].join(',')}"
  else
    'shared'
  end
end

def process_commits(commits, git_repo, yaml_path, nodeset_history, known_nodeset)
  commits.each do |date, sha|
    yaml_content = known_nodeset.to_h { |a| [a, nil] }.update(load_yaml_from_git(git_repo, sha, yaml_path))
    yaml_content.each do |nodeset, prio|
      nodeset_history[nodeset] ||= []
      mode = prio_mode(prio)
      update_history(nodeset_history, nodeset, date, mode)
      known_nodeset.add(nodeset)
    end
  end
end

def load_yaml_from_git(git_repo, sha, yaml_path)
  relative_path = yaml_path.sub(git_repo.repo.path.gsub(/\.git$/, ''), '')
  YAML.load(git_repo.show("#{sha}:#{relative_path}"), **$yaml_load_args) || {}
end

# Update history only if the mode changed, if so we terminate the last entry and
# add a new one
def update_history(nodeset_history, nodeset, date, mode)
  last_entry = nodeset_history[nodeset].last
  return unless last_entry.nil? || (last_entry[1] == 'ACTIVE' && last_entry[2] != mode)

  last_entry[1] = date.dup if last_entry
  nodeset_history[nodeset] << [date.dup, 'ACTIVE', mode]
end

def generate_nodeset_mode_history
  site_data_hierarchy = load_data_hierarchy
  nodeset_history = {}
  git_repo = Git.open(".")
  diff = git_repo.diff.name_status.keys.select { |x| x.start_with?(INPUT_FOLDER) }
  unless diff.empty?
    abort "Please commit your changed on: #{diff.join(',')}. This generator use the git history to build history of the access mode of the nodes"
  end
  site_data_hierarchy['sites'].each_key do |site|
    known_nodeset = Set.new
    yaml_path = File.join(INPUT_FOLDER, "#{site}.yaml")
    next unless File.exist?(yaml_path)

    commits = git_repo.log.path(yaml_path).map { |commit| [commit.author.date, commit.sha] }.sort_by(&:first)
    process_commits(commits, git_repo, yaml_path, nodeset_history, known_nodeset)
  end

  nodeset_history
end

##########################################
#   access level generation              #
##########################################

# Helper function
def value_and_tail_iterator(array)
  Enumerator.new do |yielder|
    array.each_with_index do |value, index|
      yielder.yield [value, array[(index + 1)..-1]]
    end
  end
end

def priority_to_level(priority)
  case priority
  when 'p1'
    40
  when 'p2'
    30
  when 'p3'
    20
  when 'p4'
    10
  when 'besteffort'
    0
  end
end

def determine_access_level(expanded_ggas, gga)
  value_and_tail_iterator(%w[p1 p2 p3 p4 besteffort]).each do |level, lower_levels|
    next unless expanded_ggas[level]&.delete(gga)

    lower_levels.each { |l| expanded_ggas[l]&.delete(gga) }
    return { 'label' => level, 'level' => priority_to_level(level) }
  end
  { 'label' => 'no-access', 'level' => -1 }
end

def create_access(prio, nodeset)
  expanded_ggas = prio.transform_values { |x| expand_ggas(x) }
  puts "Warning: No prio defined for #{nodeset}" if expanded_ggas.values.flatten.empty?
  h = ALL_GGAS.map { |x| x['name'] }.sort.map do |gga|
    level_info = determine_access_level(expanded_ggas, gga)
    [gga, level_info]
  end.to_h
  expanded_ggas.each do |_, remanding_gga|
    unless remanding_gga.empty?
      puts "Warning: Some gga specified for the #{nodeset} nodeset do not exist: #{remanding_gga.join(',')}"
    end
  end
  h
end

def expand_ggas(ggas)
  return [] if ggas.nil?

  expanded_ggas = []
  ggas.each do |group|
    to_remove = group.start_with?('-')
    group = group[1..-1] if to_remove

    if group.start_with?('%')
      site = group[1..-1]
      abort "Error: Unable to expand %#{site}: no site of that name" unless ALL_SITES.include?(site)
      site_gga = ALL_GGAS.select { |x| x['site'] == site }.map { |x| x['name'] }
      if site_gga.empty?
        puts "Warning: expanding %#{site} gave no gga"
      end
      expanded_ggas = to_remove ? expanded_ggas - site_gga : expanded_ggas + site_gga
    elsif group.start_with?('@')
      group_gga = group[1..-1]
      unless $group_of_gga.key?(group_gga)
        abort "Error: Unable to expand @#{group_gga}: group of gga is not not defined?"
      end
      expanded_ggas = to_remove ? expanded_ggas - $group_of_gga[group_gga] : expanded_ggas + $group_of_gga[group_gga]
    elsif to_remove
      expanded_ggas.delete(group)
    else
      expanded_ggas << group
    end
  end
  expanded_ggas.uniq
end

def generate_access_level
  site_data_hierarchy = load_data_hierarchy
  group_config_path = File.join(INPUT_FOLDER, 'group.yaml')
  if File.exist?(group_config_path)
    YAML.load_file(group_config_path).each do |k, v|
      $group_of_gga[k] = expand_ggas(v)
    end
  else
    # FIXME: put some "skip" in the yaml, and remove useless yamls.
    puts 'Warning: Skipping group configuration since there is no file'
  end

  nodesets = {}
  site_data_hierarchy['sites'].each_key do |site|
    site_config_path = File.join(INPUT_FOLDER, "#{site}.yaml")
    if File.exist?(site_config_path)
      yaml_access_file = YAML.load_file(site_config_path, **$yaml_load_args)
      unless yaml_access_file
        puts "Warning: #{site} configuration is present but empty"
        next
      end
      nodesets.update(yaml_access_file) unless IGNORE_SITES.include?(site)
    end
  end
  unspecified_nodesets = all_nodesets - nodesets.keys
  overspecified_nodesets = nodesets.keys - all_nodesets
  abort "Some nodeset are not configure: #{unspecified_nodesets.join(', ')}" unless unspecified_nodesets.empty?
  puts "Warning: Some unkown (or not production) nodeset ARE configured : #{overspecified_nodesets.join(', ')}" unless overspecified_nodesets.empty?
  nodesets.each_with_object({}) do |(nodeset, prio_input), acc|
    create_access(prio_input, nodeset).each do |gga, prio|
      acc[gga] = {} unless acc.key?(gga)
      acc[gga][nodeset] = prio
    end
  end
end

def all_nodesets
  site_data_hierarchy = load_data_hierarchy
  nodesets = []
  site_data_hierarchy['sites'].each do |_site, site_details|
    site_details.fetch('clusters', {}).each do |_cluster, cluster_details|
      next unless cluster_details['queues'].include?('production')

      nodesets.concat(cluster_details['nodes'].map { |_, node_details| node_details['nodeset'] })
    end
  end
  nodesets.uniq
end
