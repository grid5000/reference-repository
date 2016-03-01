#!/usr/bin/ruby

# Generator for the OAR properties

require 'pp'
require 'erb'
require 'fileutils'
require 'pathname'
require 'json'
require 'time'
require 'yaml'
require 'hashdiff'
require 'optparse'
require 'net/ssh'

require '../oar-properties/lib/lib-oar-properties'
require '../lib/input_loader'

options = {}
options[:sites] = %w{grenoble lille luxembourg lyon nantes reims rennes sophia}
options[:diff]  = false

OptionParser.new do |opts|
  opts.banner = "Usage: oar-properties.rb [options]"

  opts.separator ""
  opts.separator "Example: ruby oar-properties.rb -v -s nancy -d oarnodes-%s.yaml -o cmd-%s.sh"

  opts.separator ""
  opts.separator "Filters:"

  ###

  opts.on('-s', '--sites a,b,c', Array, 'Select site(s)',
                                        "Default: "+options[:sites].join(", ")) do |s|
    options[:sites] = s
  end

  opts.on('-c', '--clusters a,b,c', Array, 'Select clusters(s). Default: all') do |s|
    options[:clusters] = s
  end

  opts.on('-n', '--nodes a,b,c', Array, 'Select nodes(s). Default: all') do |n|
    options[:nodes] = n
  end

  ###

  opts.separator ""
  opts.separator "Output options:"

  opts.on('-o', '--output', 'Output oarnodesetting command into a file. Default: stdout') do |o|
    options[:output] = o
  end

  opts.on('-e', '--exec', 'Directly apply the changes to the OAR server') do |e|
    options[:exec] = e
  end
  
  opts.on("-d", "--diff [YAML filename]", 
          "Only generates the minimal list of commands needed to update the site configuration",
          "The optional YAML file is suppose to be the output of the 'oarnodes -Y' command.",
          "If the file does not exist, the script will get the data from the OAR server and save the result on disk for future use.",
          "If no filename is specified, the script will simply connect to the OAR server.",
          "You can use the '%s' placeholder for 'site'. Ex: oarnodes-%s.yaml") do |d|
    d = true if d == nil
    options[:diff] = d
  end
    
#  opts.on("-n", "--dry-run", "Perform a trial run with no changes made") do |n|
#    options[:dryrun] = n
#  end

  ###

  opts.separator ""
  opts.separator "Common options:"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  
  # Print an options summary.
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

pp options

nodelist_properties = {} # ["ref"]  : properties from the reference-repo
                         # ["oar"]  : properties from the OAR server
                         # ["diff"] : diff between "ref" and "oar"

#
# Get the OAR properties from the reference-repo (["ref"])
#

nodelist_properties["ref"] = {}
global_hash = load_yaml_file_hierarchy('../../input/grid5000/')
options[:sites].each { |site_uid| 
  nodelist_properties["ref"][site_uid] = get_nodelist_properties(site_uid, global_hash["sites"][site_uid]) 
}

#
# Get the current OAR properties from the OAR scheduler (["oar"])
#

nodelist_properties["oar"] = {}
options[:sites].each { |site_uid| 
  nodelist_properties["oar"][site_uid] = {}

  # This is only needed for the -d option  
  if options[:diff]
    filename = options[:diff].is_a?(String) ? options[:diff].gsub("%s", site_uid) : nil
    nodelist_properties["oar"][site_uid] = oarcmd_get_nodelist_properties(site_uid, filename)
  end
}

#
# Diff
#

nodelist_properties["to_be_updated"] = {}

nodelist_properties["ref"].each { |site_uid, site_properties| 
  
  site_properties.sort_by { |item| item.to_s.split(/(\d+)/).map { |e| [e.to_i, e] } }.each { |node_uid, node_properties_ref|
    cluster_uid = node_uid.split(/-/).first

    if (! options[:clusters] || options[:clusters].include?(cluster_uid)) &&
        (! options[:nodes] || options[:nodes].include?(node_uid))
      
      node_properties_oar = nodelist_properties["oar"][site_uid][node_uid]
      
      diff      = diff_node_properties(node_properties_ref, node_properties_oar)
      diff_keys = diff.map{ |hashdiff_array| hashdiff_array[1] }

      nodelist_properties["to_be_updated"][node_uid] = node_properties_ref.select { |key, value| diff_keys.include?(key) }
      
      if (options[:verbose])
        #puts "#{node_uid}: #{diff}"
        puts "#{node_uid}: #{diff_keys}"
      end

    end

    }
  
}


#
# Example
#
#puts oarcmd_set_node_properties("graphene-1", node_properties["oar"])
#puts oarcmd_set_node_properties("graphene-1", node_properties["to_be_updated"])
