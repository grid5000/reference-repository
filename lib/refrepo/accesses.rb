# frozen_string_literal: true

require 'refrepo/data_loader'
require 'git'

PRIOLEVEL = {
  'p1' => 40,
  'p2' => 30,
  'p3' => 20,
  'p4' => 10,
  'besteffort' => 0
}.freeze
INPUT_FOLDER = 'input/grid5000/access'
YAML_LOAD_ARGS = if ::Gem::Version.new(RUBY_VERSION) >= ::Gem::Version.new('3.1.0')
                   { aliases: true }
                 else
                   {}
                 end.freeze

# Parses and stores expanded group structures
# also epands any list given to expand(...)
class GgaGroups
  def initialize(filepath = nil)
    @groups = {}
    load_file(filepath) if filepath
  end

  def get(name)
    @groups[name]
  end

  def expand(list)
    parse_def(list)
  end

  def load_file(filepath)
    if File.exist?(filepath)
      YAML.load_file(filepath, **YAML_LOAD_ARGS).each do |name, v|
        groupdef = parse_def(v)
        set(name, groupdef)
      rescue RuntimeError => e
        raise e.exception("#{e.message}, when parsing group #{v} in #{filepath}")
      end
    else
      # FIXME: put some "skip" in the yaml, and remove useless yamls.
      puts 'Warning: Skipping group configuration since there is no file'
    end
  end

  def set(name, groupdef)
    raise "Trying to redefine existing access group #{name}" if @groups.key? name
    raise "Bad group definition for #{name}: #{groupdef.pretty_inspect}" unless check_def(groupdef)

    @groups[name] = groupdef
  end

  private

  def check_def(groupdef)
    %w[ggas sites].all? { |k| groupdef.key? k }
  end

  def parse_def(group_list)
    definition = {}
    %w[ggas sites].each { |k| definition[k] = [] }

    group_list.each do |element|
      case element[0]
      when '@'
        other_group = get(element[1..])
        raise "Couldn't find find group #{element}" if other_group.nil?

        definition['sites'] |= other_group['sites']
        definition['ggas'] |= other_group['ggas']
      when '%'
        definition['sites'].push(element[1..])
      else
        definition['ggas'].push(element)
      end
    end
    definition['ggas'].uniq
    definition['sites'].uniq
    definition
  end
end

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

def drop(str, num = 1)
  str[num..]
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
  YAML.load(git_repo.show("#{sha}:#{relative_path}"), **YAML_LOAD_ARGS) || {}
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
  git_repo = Git.open('.')
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

def expand_nodeset_lists
  group_config_path = File.join(INPUT_FOLDER, 'group.yaml')
  groups = GgaGroups.new(group_config_path)

  inputs = load_nodeset_inputs

  unspecified_nodesets = all_nodesets - inputs.keys
  overspecified_nodesets = inputs.keys - all_nodesets
  abort "Some nodeset are not configure: #{unspecified_nodesets.join(', ')}" unless unspecified_nodesets.empty?
  unless overspecified_nodesets.empty?
    puts "Warning: Some unkown (or not production) nodeset ARE configured : #{overspecified_nodesets.join(', ')}"
  end

  outputs = inputs.each_with_object({}) do |(nodeset, access_hash), output|
    output[nodeset] = expands_acces_hashes(access_hash, groups)
  rescue RuntimeError => e
    raise e.exception "#{e.message} when processing input nodeset #{nodeset}"
  end

  outputs
end

# Eats a {p1 => [@group,%site,gga], p2=> ... } hash of lists
# Outputs a { p1 => {ggas => [...], sites => [...]}, p2 => ...} unaliased hash of hashes
def expands_acces_hashes(hash, ggagroups)
  hash.transform_values { |list| ggagroups.expand(list) }
end

def load_nodeset_inputs
  access_hash = {}
  site_data_hierarchy = load_data_hierarchy
  site_data_hierarchy['sites'].each_key do |site|
    site_config_path = File.join(INPUT_FOLDER, "#{site}.yaml")
    next unless File.exist?(site_config_path)

    yaml_access_file = YAML.load_file(site_config_path, **YAML_LOAD_ARGS)
    unless yaml_access_file
      puts "Warning: #{site} configuration is present but empty"
      next
    end
    access_hash.update(yaml_access_file)
  end
  access_hash
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
