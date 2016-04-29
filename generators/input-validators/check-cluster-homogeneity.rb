#!/usr/bin/ruby

# This script checks the cluster homogeneity

if RUBY_VERSION < "2.1"
  puts "This script requires ruby >= 2.1"
  exit
end

require 'pp'
require 'fileutils'
require 'pathname'
require 'hashdiff'

dir = Pathname(__FILE__).parent

require "#{dir}/../lib/input_loader"

def global_ignore_keys()

  #
  # Global ignore keys
  #

  ignore_keys = %w(
    ~chassis.serial
  
    ~network_adapters.bmc.ip
    ~network_adapters.bmc.mac
    ~network_adapters.bmc.network_address
    ~network_adapters.bmc.switch
    ~network_adapters.bmc.switch_port
  
    ~network_adapters.ib0.guid
    ~network_adapters.ib0.hwid
    ~network_adapters.ib0.ip
    ~network_adapters.ib0.ip6
    ~network_adapters.ib0.line_card
    ~network_adapters.ib0.position
    ~network_adapters.ib1.guid
  
    ~network_adapters.myri0.ip
    ~network_adapters.myri0.ip6
    ~network_adapters.myri0.mac
    ~network_adapters.myri0.network_address
  
    ~pdu
    ~pdu.port
    ~pdu.uid
    ~pdu[0]
    ~pdu[1]

    ~supported_job_types.max_walltime

    ~mic.ip
    ~mic.mac

    +status
    -status
  )

  ignore_netkeys = <<-eos
    ~network_adapters.eth.ip
    ~network_adapters.eth.ip6
    ~network_adapters.eth.mac
    ~network_adapters.eth.network_address
    ~network_adapters.eth.switch
    ~network_adapters.eth.switch_port
    ~network_adapters.eth.ip
    ~network_adapters.eth.ip6
    ~network_adapters.eth.mac
    ~network_adapters.eth.switch_port
    ~network_adapters.eth.ip
    ~network_adapters.eth.ip6
    ~network_adapters.eth.mac
    ~network_adapters.eth.switch_port
    ~network_adapters.eth.ip
    ~network_adapters.eth.mac
    ~network_adapters.eth.mac
    ~network_adapters.eth.mac
eos

  ignore_stokeys = <<-eos
    ~storage_devices.sd.model
    ~storage_devices.sd.rev
    ~storage_devices.sd.size
    ~storage_devices.sd.timeread
    ~storage_devices.sd.timewrite
    ~storage_devices.sd.vendor
eos

  (0..5).each { |eth| 
    keys = ignore_netkeys.gsub('.eth.', ".eth#{eth}.").gsub("\n", " ").split(" ")
    ignore_keys.push(* keys)

    (1..21).each { |kavlan|
      ignore_keys << "~kavlan.eth#{eth}.kavlan-#{kavlan}"
    }
  }

  ('a'..'d').each { |sd| 
    keys = ignore_stokeys.gsub('.sd.', ".sd#{sd}.").gsub("\n", " ").split(" ")
    ignore_keys.push(* keys)
  }

  return ignore_keys
end

def cluster_ignore_keys(filename)
  file_hash = YAML::load(ERB.new(File.read(filename)).result(binding))
  file_hash.expand_square_brackets() if file_hash
  return file_hash
end

def cluster_homogeneity(refapi_hash, verbose=false)
  if verbose
    puts "The change set is represented using the following syntax:"
    puts '  [["+", "path.to.key1", value],          # new key'
    puts '   ["-", "path.to.key2", value],          # missing key'
    puts '   ["~", "path.to.key3", value1, value2]] # modified value'
    puts ''
  end

  ignore_keys  = global_ignore_keys()
  cignore_keys = cluster_ignore_keys("../input-validators/check-cluster-homogeneity.yaml.erb")

  refapi_hash = load_yaml_file_hierarchy("../../input/grid5000/")
  count = {}
  
  refapi_hash["sites"].sort.each do |site_uid, site|
    count[site_uid] = {}

    site["clusters"].sort.each do |cluster_uid, cluster|
      count[site_uid][cluster_uid] = 0

      refnode_uid = cluster['nodes'].keys.sort.first
      refnode = cluster['nodes'][refnode_uid]
      
      cluster["nodes"].each_sort_by_node_uid do |node_uid, node|
        #next if node_uid != 'graphene-2'
        
        diffs = HashDiff.diff(refnode, node)

        # Hack HashDiff output for arrays:
        #[["-", "pdu[1]", {"uid"=>"graphene-pdu9", "port"=>24}],
        # ["-", "pdu[0]", {"uid"=>"graphene-pdu9", "port"=>23}],
        # ["+", "pdu[0]", {"uid"=>"graphene-pdu9", "port"=>21}],
        # ["+", "pdu[1]", {"uid"=>"graphene-pdu9", "port"=>22}]]
        # => should be something like this:
        # [["~", "pdu[0]", {"uid"=>"graphene-pdu9", "port"=>23}, {"uid"=>"graphene-pdu9", "port"=>22},
        #  ["~", "pdu[1]", {"uid"=>"graphene-pdu9", "port"=>24}, {"uid"=>"graphene-pdu9", "port"=>23}}
        d = diffs.select{|x| x[0] != '~' }.group_by{ |x| x[1] }
        d.each { |k, v|
          d[k] = v.group_by{ |x| x[0] }
        }
        d.each { |k,v|
          if v.key?('-') && v.key?('+')
            #puts "Warning: #{node_uid}: convert +/- -> ~ for #{k}"
            diffs.delete(["-", k, v['-'][0][2]])
            diffs.delete(["+", k, v['+'][0][2]])
            diffs << ["~", k, v['-'][0][2], v['+'][0][2] ]
          end
        }
        # end of hack

        # Remove keys that are specific to each nodes (ip, mac etc.)
        ikeys = cignore_keys[site_uid][node_uid] rescue nil
        diffs.clone.each { |diff|
          diffs.delete(diff) if ignore_keys.include?(diff[0] + diff[1])         
          diffs.delete(diff) if ikeys && ikeys.include?(diff[0] + diff[1]) 
        }

        if verbose && !diffs.empty?
          puts "Differences between #{refnode_uid} and #{node_uid}:"
          pp diffs
        end

        count[site_uid][cluster_uid] += diffs.size

        # Remove the following line if you want to compare each nodes to the first cluster node
        refnode_uid = node_uid
        refnode = node

      end
      
    end
  end

  return count
end

def check_cluster_homogeneity(refapi_hash, verbose=false)
  puts "Differences found between successive nodes, per cluster:\n\n"

  count = cluster_homogeneity(refapi_hash, verbose)
  puts "\n" if verbose

  puts count.to_yaml unless verbose

  puts "\nUse '../input-validators/check-cluster-homogeneity.rb -v' for details." unless verbose
  
  return count
end

if __FILE__ == $0
  require 'optparse'

  options = {}

  OptionParser.new do |opts|
    opts.banner = "Usage: check-cluster-homogeneity.rb [options]"

    opts.separator ""
    opts.separator "Example: ruby check-cluster-homogeneity.rb -v"
    opts.separator ""

    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      options[:verbose] ||= 0
      options[:verbose] = options[:verbose] + 1
    end
  
    # Print an options summary.
    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end.parse!

  refapi_hash = load_yaml_file_hierarchy("#{dir}/../../input/grid5000/")
  check_cluster_homogeneity(refapi_hash, options.key?(:verbose))
end
