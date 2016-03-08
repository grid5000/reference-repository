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
options[:sites] = %w{grenoble lille luxembourg lyon nancy nantes reims rennes sophia}
options[:diff]  = false
options[:sshkeys]  = []

OptionParser.new do |opts|
  opts.banner = "Usage: oar-properties.rb [options]"

  opts.separator ""
  opts.separator "Example: ruby oar-properties.rb -v -s nancy -d oarnodes-%s.yaml -o cmd-%s.sh"

  opts.separator ""
  opts.separator "Filters:"

  ###

  opts.on('-s', '--sites a,b,c', Array, 'Select site(s)',
                                        "Default: "+options[:sites].join(", ")) do |s|
    raise "Wrong argument for -s option." unless (s - options[:sites]).empty?
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

  opts.on('-o', '--output [FILE]', 'Output oarnodesetting commands to a file. Default FILE is stdout.') do |o|
    o = true if o == nil
    options[:output] = o
  end

  opts.on('-e', '--exec', 'Directly apply the changes to the OAR server') do |e|
    options[:exec] = e
  end

  opts.on('-k', '--ssh-keys k1,k2,k3', Array, 'SSH keys') do |k|
    options[:sshkeys] = k
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
    
  ###

  opts.separator ""
  opts.separator "Common options:"

  opts.on("-v", "--[no-]verbose", "Run verbosely", "Multiple -v options increase the verbosity. The maximum is 3.") do |v|
    options[:verbose] ||= 0
    options[:verbose] = options[:verbose] + 1
  end
  
  # Print an options summary.
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

puts "Options: #{options}" if options[:verbose]

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

# This is only needed for the -d option  
if options[:diff]
  nodelist_properties["oar"] = {}
  options[:sites].each { |site_uid| 
    nodelist_properties["oar"][site_uid] = {}
    filename = options[:diff].is_a?(String) ? options[:diff].gsub("%s", site_uid) : nil
    nodelist_properties["oar"][site_uid] = oarcmd_get_nodelist_properties(site_uid, filename, options[:sshkeys])
  }
end

#
# Diff
#
if options[:diff]
  header ||= false
  prev_diff = {}
  
  nodelist_properties["diff"] = {}
  
  nodelist_properties["ref"].each { |site_uid, site_properties| 
    nodelist_properties["diff"][site_uid] = {}

    site_properties.each_filtered_node_uid(options[:clusters], options[:nodes]) { |node_uid, node_properties_ref|
      
      node_properties_oar = nodelist_properties["oar"][site_uid][node_uid]
      
      diff      = diff_node_properties(node_properties_oar, node_properties_ref)
      diff_keys = diff.map{ |hashdiff_array| hashdiff_array[1] }
      
      nodelist_properties["diff"][site_uid][node_uid] = node_properties_ref.select { |key, value| diff_keys.include?(key) }
      
      case options[:verbose]
      when 1
        puts "#{node_uid}: #{diff_keys}"
      when 2
        # Give more details
        # puts "#{node_uid}: #{diff}"
        if !header
          header=true
          puts "Output format: ['~', 'key', 'old value', 'new value']"
        end
        if diff.size==0
          puts "  #{node_uid}: OK"
        elsif diff == prev_diff
          puts "  #{node_uid}: same as above"
        else
          puts "  #{node_uid}:"
          diff.each { |d| puts "    #{d}" } 
        end
        prev_diff = diff
      when 3
        # Even more details
        puts JSON.pretty_generate({node_uid => {"old values" => node_properties_oar, "new values" => node_properties_ref}})
      end
    }
    
  }
end # if options[:diff]

#
# Output commands
#
if options[:output]
  opt = options[:diff] ? 'diff' : 'ref'
  nodelist_properties[opt].each { |site_uid, site_properties| 
    
    options[:output].is_a?(String) ? o = File.open(options[:output].gsub("%s", site_uid),'w') : o = $stdout.dup

    site_properties.each_filtered_node_uid(options[:clusters], options[:nodes]) { |node_uid, node_properties|
      o.write(oarcmd_set_node_properties(node_uid + "." + site_uid + ".grid5000.fr", node_properties) + "\n")
    }
    
    o.close
    
  }
end

#
# Execute commands
#
if options[:exec]
  printf "Apply changes to the OAR servers ? (y/n)"
  prompt = STDIN.gets.chomp
  exit unless prompt == 'y'

  opt = options[:diff] ? 'diff' : 'ref'
  nodelist_properties[opt].each { |site_uid, site_properties| 
    
    puts "Connecting #{site_uid} ..."
    Net::SSH.start("oar.#{site_uid}.g5kadmin", 'g5kadmin', :keys => options[:sshkeys]) { |ssh|
    
      site_properties.each_filtered_node_uid(options[:clusters], options[:nodes]) { |node_uid, node_properties|
        cmd = oarcmd_set_node_properties(node_uid + "." + site_uid + ".grid5000.fr", node_properties)
        if cmd.size>0
          puts "#{cmd}" if options[:verbose]
          ssh_output = ssh.exec!('sudo ' + cmd) 
          puts "#{ssh_output}\n" if options[:verbose]
        end
      }
    }
  }
end
