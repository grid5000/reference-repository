#!/usr/bin/ruby
# coding: utf-8
#
# This program is a generator for the OAR properties
# We use two data structures of the same form to store the properties from the ref-repo
# and the properties from OAR. We can compare the two data structures to make a diff.
#
# The data structures are of the form: properties[site_uid][type][id] = { key: value, ... }
# where, for the node properties: type = 'default' and id = node_uid
# and,  for the disk properties: type = 'disk' and id = [node_uid, disk_id]
#
# By example:
# properties =
# {"nancy"=>
#   {"default"=>
#     {"grimoire-1"=>
#       {"ip"=>"172.16.129.44",
#        "cluster"=>"grimoire",
#        "host"=>"grimoire-1.nancy.grid5000.fr"
#        "network_address"="grimoire-1.nancy.grid5000.fr"
#        "disk_reservation_count"=>5,
#        ...
#       },
#     "grimoire-2"=>...,
#     },
#   }
#   {"disk"=>
#     {["grimoire-1", "sdb.grimoire-1"]=>
#       {"cluster"=>"grimoire",
#        "host"=>"grimoire-1.nancy.grid5000.fr"
#        "network_address"="grimoire-1.nancy.grid5000.fr"
#        "disk"=>1
#        "diskpath"=>"/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:1:0"
#        "cpuset"=>"disk-1"
#       },
#      ["grimoire-1", "sdc.grimoire-1"]=>...,
#      ...
#      ["grimoire-2", "sdb.grimoire-2"]=>...,
#     }
#   }
# }

if RUBY_VERSION < '2.1'
  puts 'This script requires ruby >= 2.1'
  exit
end

require 'pp'
require 'erb'
require 'fileutils'
require 'pathname'
require 'json'
require 'time'
require 'yaml'
require 'set'
require 'hashdiff'
require 'optparse'
require 'net/ssh'

require_relative '../oar-properties/lib/lib-oar-properties'
require_relative '../lib/input_loader'

def parse_command_line_parameters
  options = {}
  options[:sites] = %w(grenoble lille luxembourg lyon nancy nantes rennes sophia)
  options[:ssh] ||= {}
  options[:api] ||= {}

  OptionParser.new do |opts|
    opts.banner = 'Usage: oar-properties.rb [options]'
    opts.separator ''
    opts.separator 'Example: ruby oar-properties.rb -v -s nancy -d oarnodes-%s.json -o cmd-%s.sh'
    opts.separator ''

    opts.separator 'Filters:'
    opts.on('-s', '--sites a,b,c', Array, 'Select site(s)',
            'Default: ' + options[:sites].join(', ')) do |s|
      raise 'Wrong argument for -s option.' unless (s - options[:sites]).empty?
      options[:sites] = s
    end
    opts.on('-c', '--clusters a,b,c', Array, 'Select clusters(s). Default: all') do |s|
      options[:clusters] = s
    end
    opts.on('-n', '--nodes a,b,c', Array, 'Select nodes(s). Default: all') do |n|
      options[:nodes] = n
    end
    opts.separator ''

    opts.separator 'Output options:'
    opts.on('-o', '--output [FILE]', 'Output oarnodesetting commands to a file. Default FILE is stdout.') do |o|
      o = true if o.nil?
      options[:output] = o
    end
    opts.on('-e', '--exec', 'Directly apply the changes to the OAR server') do |e|
      options[:exec] = e
    end
    opts.on('-d', '--diff [JSON filename]',
            'Only generates the minimal list of commands needed to update the site configuration',
            "The optional JSON file is supposed to be the output of the 'oarnodes -J' command.",
            'If the file does not exist, the script will get the data from the OAR server and save the result on disk for future use.',
            'If no filename is specified, the script will simply connect to the OAR server.',
            "You can use the '%s' placeholder for 'site'. Ex: oarnodes-%s.json") do |d|
      d = true if d.nil?
      options[:diff] = d
      # If diff is set with no --output or --exec, the return code will be 0 if there are no differences, 1 otherwise
    end
    opts.separator ''

    opts.separator 'SSH options:'
    opts.on('--vagrant', 'This option modifies the SSH parameters to use a vagrant box instead of Grid5000 servers.') do | |
      options[:ssh][:host] = '127.0.0.1' unless options[:ssh][:host]
      options[:ssh][:user] = 'vagrant'   unless options[:ssh][:user]
      options[:ssh][:params] ||= {}
      options[:ssh][:params][:keys] ||= []
      options[:ssh][:params][:keys] << '~/.vagrant.d/insecure_private_key'
      options[:ssh][:params][:port] = 2222 unless options[:ssh][:params][:port]
    end
    opts.on('--ssh-host hostname', String, "Hostname of the OAR server(s). Default: 'oar.%s.g5kadmin'") do |h|
      options[:ssh][:host] = h
    end
    opts.on('--ssh-user login', String, "User login to connect the OAR server(s). Default: 'g5kadmin'") do |u|
      options[:ssh][:user] = u
    end
    opts.on('--ssh-keys k1,k2,k3', Array, 'SSH keys') do |k|
      options[:ssh][:params] ||= {}
      options[:ssh][:params][:keys] ||= []
      options[:ssh][:params][:keys] << k
    end
    opts.separator ''

    opts.separator 'Misc:'
    opts.on('--check', 'Perform extra checks.', 'Compare the node list of the OAR server with the reference-repo.') do |c|
      puts '*** Warning: --check requires --diff.' unless options[:diff]
      options[:check] = c
    end
    opts.separator ''
    opts.separator 'API authentication options:'

    opts.on('--api-user user', String, 'HTTP authentication user when outside G5K') do |user|
      options[:api][:user] = user
    end

    opts.on('--api-password pwd', String, 'HTTP authentication password when outside G5K') do |pwd|
      options[:api][:pwd] = pwd
    end

    opts.separator ''
    opts.separator 'Common options:'
    opts.on('-v', '--[no-]verbose', 'Run verbosely', 'Multiple -v options increase the verbosity. The maximum is 3.') do | |
      options[:verbose] ||= 0
      options[:verbose] = options[:verbose] + 1
    end

    # Print an options summary.
    opts.on_tail('-h', '--help', 'Show this message') do
      puts opts
      exit
    end
  end.parse!

  options[:ssh][:user] = 'g5kadmin'        unless options[:ssh][:user]
  options[:ssh][:host] = 'oar.%s.g5kadmin' unless options[:ssh][:host]
  options[:ssh][:params] ||= {}
  options[:diff] = false unless options[:diff]

  if options[:output] && options[:output] != true &&
     !options[:output].include?('%s') &&
     options[:sites].length > 1

    raise "Can't write several sites to only one file '#{options[:output]}' (add '%s' to the file name to create one file per site)"
  end

  puts "Options: #{options}" if options[:verbose]

  puts 'Hint: You might want to use either --verbose, --output or --exec.' unless options[:verbose] || options[:output] || options[:exec]

  return options
end

# Get the properties of each node
def get_oar_properties_from_the_ref_repo(global_hash, options)
  properties = {}
  sites = options[:sites]
  sites.each do |site_uid|
    properties[site_uid] = {}
    properties[site_uid]['default'] = get_ref_default_properties(site_uid, global_hash['sites'][site_uid])
    properties[site_uid]['disk'] = get_ref_disk_properties(site_uid, global_hash['sites'][site_uid])
  end
  return properties
end

def get_oar_properties_from_oar(options)
  properties = {}
  sites = options[:sites]
  diff = options[:diff]
  sites.each do |site_uid|
    filename = diff.is_a?(String) ? diff.gsub('%s', site_uid) : nil
    properties[site_uid] = {}
    properties[site_uid]['default'] = get_oar_default_properties(site_uid, filename, options)
    properties[site_uid]['disk'] = get_oar_disk_properties(site_uid, filename, options)
  end
  return properties
end

# Main program
# properties['ref'] = properties from the reference-repo
# properties['oar'] = properties from the OAR server
# properties['diff'] = diff between "ref" and "oar"

ret = true
options = parse_command_line_parameters
global_hash = load_yaml_file_hierarchy(File.expand_path('../../input/grid5000/', File.dirname(__FILE__)))

properties = {}
properties['ref'] = get_oar_properties_from_the_ref_repo(global_hash, options)

# Get the list of property keys from the reference-repo (['ref'])
properties_keys = {}
properties_keys['ref'] = get_property_keys(properties['ref'])
ignore_default_keys = ignore_default_keys()

# Diff
if options[:diff]
  properties['oar'] = get_oar_properties_from_oar(options)

  # Build the list of nodes that are listed in properties['oar'],
  # but does not exist in properties['ref']
  # We distinguish 'Dead' nodes and 'Alive'/'Absent'/etc. nodes
  missings_alive = []
  missings_dead = []
  properties['oar'].each do |site_uid, site_properties|
    site_properties['default'].each_filtered_node_uid(options[:clusters], options[:nodes]) do |node_uid, node_properties_oar|
      unless properties['ref'][site_uid]['default'][node_uid]
        node_properties_oar['state'] != 'Dead' ? missings_alive << node_uid : missings_dead << node_uid
      end
    end
  end

  if missings_alive.size > 0
    puts "*** Error: The following nodes exist in the OAR server but are missing in the reference-repo: #{missings_alive.join(', ')}.\n"
    ret = false unless options[:exec] || options[:output]
  end

  if missings_dead.size > 0 && options[:check]
    puts "*** Warning: The following 'Dead' nodes exist in the OAR server but are missing in the reference-repo: #{missings_dead.join(', ')}.
Those nodes should be marked as 'retired' in the reference-repo.\n"
    ret = false unless options[:exec] || options[:output]
  end

  skipped_nodes = []
  prev_diff = {}
  properties['diff'] = {}
  properties_keys['oar'] = Set.new []

  header = false
  properties['ref'].each do |site_uid, site_properties|
    properties['diff'][site_uid] = {}
    site_properties.each do |type, type_properties|
      properties['diff'][site_uid][type] = {}
      type_properties.each_filtered_node_uid(options[:clusters], options[:nodes]) do |key, properties_ref|
        # As an example, key can be equal to 'grimoire-1' for default resources or
        # ['grimoire-1', 1] for disk resources (disk n°1 of grimoire-1)
        node_uid, = key

        if properties_ref['state'] == 'Dead'
          skipped_nodes << node_uid
          next
        end

        properties_oar = properties['oar'][site_uid][type][key]

        diff = diff_properties(type, properties_oar, properties_ref) # Note: this deletes some properties from the input parameters
        diff_keys = diff.map { |hashdiff_array| hashdiff_array[1] }
        properties['diff'][site_uid][type][key] = properties_ref.select { |k, _v| diff_keys.include?(k) }

        # Verbose output
        info = type == 'default' ? ' new node !' : ' new disk !' if properties['oar'][site_uid][type][key].nil?
        case options[:verbose]
        when 1
          puts "#{key}:#{info}" if info != ''
          puts "#{key}:#{diff_keys}" if diff.size != 0
        when 2
          # Give more details
          if header == false
            puts "Output format: ['~', 'key', 'old value', 'new value']"
            header = true
          end
          if diff.empty?
            puts "  #{key}: OK#{info}"
          elsif diff == prev_diff
            puts "  #{key}:#{info} same modifications as above"
          else
            puts "  #{key}:#{info}"
            diff.each { |d| puts "    #{d}" }
          end
          prev_diff = diff
        when 3
          # Even more details
          puts "#{key}:#{info}" if info != ''
          puts JSON.pretty_generate(key => { 'old values' => properties_oar, 'new values' => properties_ref })
        end
        if diff.size != 0
          ret = false unless options[:exec] || options[:output]
        end
      end
    end
  end

  # Get the list of property keys from the OAR scheduler (['oar'])
  properties_keys['oar'] = get_property_keys(properties['oar'])

  # Build the list of properties that must be created in the OAR server
  properties_keys['diff'] = {}
  properties_keys['ref'].each do |k, v_ref|
    v_oar = properties_keys['oar'][k]
    properties_keys['diff'][k] = v_ref unless v_oar
    if v_oar && v_oar != v_ref && v_ref != NilClass && v_oar != NilClass
      # Detect inconsistency between the type (String/Fixnum) of properties generated by this script and the existing values on the server.
      puts "Error: the OAR property '#{k}' is a '#{v_oar}' on the server and this script uses '#{v_ref}' for this property."
      ret = false unless options[:exec] || options[:output]
    end
  end

  puts "Properties that need to be created on the server: #{properties_keys['diff'].keys.to_a.delete_if { |e| ignore_default_keys.include?(e) }.join(', ')}" if options[:verbose] && properties_keys['diff'].keys.to_a.delete_if { |e| ignore_default_keys.include?(e) }.size > 0

  # Detect unknown properties
  unknown_properties = properties_keys['oar'].keys.to_set - properties_keys['ref'].keys.to_set
  ignore_default_keys.each do |key|
    unknown_properties.delete(key)
  end

  if options[:verbose] && unknown_properties.size > 0
    puts "Properties existing on the server but not managed/known by the generator: #{unknown_properties.to_a.join(', ')}."
    puts "Hint: you can delete properties with 'oarproperty -d <property>' or add them to the ignore list in lib/lib-oar-properties.rb."
    ret = false unless options[:exec] || options[:output]
  end
  puts "Skipped retired nodes: #{skipped_nodes}" if skipped_nodes.any?
end # if options[:diff]

# Build and execute commands
if options[:output] || options[:exec]
  skipped_nodes = [] unless options[:diff]
  opt = options[:diff] ? 'diff' : 'ref'

  properties[opt].each do |site_uid, site_properties|
    options[:output].is_a?(String) ? o = File.open(options[:output].gsub('%s', site_uid), 'w') : o = $stdout.dup

    ssh_cmd = []
    cmd = []
    cmd << oarcmd_script_header
    cmd << oarcmd_separator

    # Create properties keys
    properties_keys[opt].delete_if { |k, _v| ignore_default_keys.include?(k) }
    unless properties_keys[opt].empty?
      cmd << oarcmd_create_properties(properties_keys[opt]) + "\n"
      cmd << oarcmd_separator
    end
    cmd << oarcmd_create_node_header
    cmd << oarcmd_separator

    # Build and output node commands
    site_properties['default'].each_filtered_node_uid(options[:clusters], options[:nodes]) do |node_uid, node_properties|
      cluster_uid = node_uid.split('-')[0]
      node_address = [node_uid, site_uid, 'grid5000.fr'].join('.')

      if node_properties['state'] == 'Dead'
        # Do not log node skipping twice if we just did a diff
        skipped_nodes << node_uid unless options[:diff]
        next
      end

      # Create new nodes
      if opt == 'ref' || properties['oar'][site_uid]['default'][node_uid].nil?
        node_hash = global_hash['sites'][site_uid]['clusters'][cluster_uid]['nodes'][node_uid]
        cmd << oarcmd_create_node(node_address, node_properties, node_hash)
      end

      # Update properties
      unless node_properties.empty?
        cmd << oarcmd_set_node_properties(node_address, node_properties)
        cmd << oarcmd_separator
      end
      ssh_cmd += cmd if options[:exec]
      o.write(cmd.join('')) if options[:output]
      cmd = []
    end

    # Build and output disk commands
    site_properties['disk'].each_filtered_node_uid(options[:clusters], options[:nodes]) do |key, disk_properties|
      # As an example, key can be equal to 'grimoire-1' for default resources or
      # ['grimoire-1', 'sdb.grimoire-1'] for disk resources (disk sdb of grimoire-1)
      node_uid, disk = key
      host = [node_uid, site_uid, 'grid5000.fr'].join('.')

      next if skipped_nodes.include?(node_uid)

      # Create a new disk
      if opt == 'ref' || properties['oar'][site_uid]['disk'][key].nil?
        cmd << oarcmd_create_disk(host, disk)
      end

      # Update the disk properties
      unless disk_properties.empty?
        cmd << oarcmd_set_disk_properties(host, disk, disk_properties)
        cmd << oarcmd_separator
      end

      ssh_cmd += cmd if options[:exec]
      o.write(cmd.join('')) if options[:output]
      cmd = []
    end
    o.close

    # Execute commands
    if options[:exec]
      printf 'Apply changes to the OAR server ' + options[:ssh][:host].gsub('%s', site_uid) + ' ? (y/N) '
      prompt = STDIN.gets.chomp
      ssh_exec(site_uid, ssh_cmd, options) if prompt == 'y'
    end
  end # site loop

  if skipped_nodes.any?
    puts "Skipped retired nodes: #{skipped_nodes}" unless options[:diff]
  end
end # if options[:output] || options[:exec]

exit ret
