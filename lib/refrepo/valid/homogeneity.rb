#!/usr/bin/ruby

# This script checks the cluster homogeneity

require 'pp'
require 'fileutils'
require 'pathname'
require 'hashdiff'
require 'json'
require 'uri'
require 'net/https'

require 'refrepo/input_loader'

def global_ignore_keys

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
  
    ~network_adapters.myri0.ip
    ~network_adapters.myri0.ip6
    ~network_adapters.myri0.mac
    ~network_adapters.myri0.network_address
  
    ~network_adapters.ib0.mac
    ~network_adapters.ib1.mac

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
    ~network_adapters.eth.rate
    ~network_adapters.eth.name
    ~network_adapters.eth.ip
    -network_adapters.eth.ip
    ~network_adapters.eth.ip6
    -network_adapters.eth.ip6
    ~network_adapters.eth.mac
    ~network_adapters.eth.network_address
    ~network_adapters.eth.switch
    ~network_adapters.eth.switch_port
eos

  ignore_stokeys = <<-eos
    ~storage_devices.sd.model
    ~storage_devices.sd.firmware_version
    ~storage_devices.sd.rev
    -storage_devices.sd.rev
    ~storage_devices.sd.size
    ~storage_devices.sd.timeread
    ~storage_devices.sd.timewrite
    ~storage_devices.sd.vendor
    ~storage_devices.sd.by_id
    ~storage_devices.sd.by_path
eos

  (0..5).each { |eth|
    keys = ignore_netkeys.gsub('.eth.', ".eth#{eth}.").gsub("\n", " ").split(" ")
    ignore_keys.push(* keys)

    (1..21).each { |kavlan|
      ignore_keys << "~kavlan.eth#{eth}.kavlan-#{kavlan}"
    }
  }

  ('a'..'f').each { |sd| 
    keys = ignore_stokeys.gsub('.sd.', ".sd#{sd}.").gsub("\n", " ").split(" ")
    ignore_keys.push(* keys)
  }

  ignore_ibkeys = <<-eos
    ~network_adapters.IB_IF.guid
    ~network_adapters.IB_IF.hwid
    ~network_adapters.IB_IF.ip
    ~network_adapters.IB_IF.ip6
    ~network_adapters.IB_IF.line_card
    ~network_adapters.IB_IF.position
    +network_adapters.IB_IF.version
eos

  ib_interfaces = [
    'ib0',
    'ib1',
    'ib0.8100'
  ]

  ib_interfaces.each { |ib_if|
    keys = ignore_ibkeys.gsub('IB_IF', "#{ib_if}").gsub("\n", " ").split(" ")
    ignore_keys.push(* keys)
  }
  return ignore_keys
end

def cluster_ignore_keys(filename)
  file_hash = YAML::load(ERB.new(File.read(filename)).result(binding))
  file_hash.expand_square_brackets() if file_hash
  return file_hash
end

def get_site_dead_nodes(site_uid, options)

  oarnodes = ''
  api_uri = URI.parse('https://api.grid5000.fr/stable/sites/' + site_uid  + '/internal/oarapi/resources/details.json?limit=999999')

  # Download the OAR properties from the OAR API (through G5K API)
  puts "Downloading OAR resources properties from #{api_uri} ..." if options[:verbose]
  http = Net::HTTP.new(api_uri.host, Net::HTTP.https_default_port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(api_uri.request_uri)

  # For outside g5k network access
  if options[:api][:user] && options[:api][:pwd]
    request.basic_auth(options[:api][:user], options[:api][:pwd])
    #request.basic_auth("nmichon", "o|JsGvGD4200")
  end

  response = http.request(request)
  raise "Failed to fetch resources properties from API: \n#{response.body}\n" unless response.code.to_i == 200
  puts '... done' if options[:verbose]
  oarnodes = JSON.parse(response.body)

  # Adapt from the format of the OAR API
  oarnodes = oarnodes['items'] if oarnodes.key?('items')
  dead_nodes = []
  oarnodes.each() { |node|
    if node["state"] == "Dead" && !dead_nodes.include?(node["network_address"])
      dead_nodes << node["network_address"].split(".")[0]
    end
  }
  return dead_nodes
end

def cluster_homogeneity(refapi_hash, options = {:verbose => false})
  verbose = options[:verbose]

  if verbose
    puts "The change set is represented using the following syntax:"
    puts '  [["+", "path.to.key1", value],          # new key'
    puts '   ["-", "path.to.key2", value],          # missing key'
    puts '   ["~", "path.to.key3", value1, value2]] # modified value'
    puts ''
  end

  ignore_keys  = global_ignore_keys()
  cignore_keys = cluster_ignore_keys(File.expand_path("data/homogeneity.yaml.erb", File.dirname(__FILE__)))

  input_data_dir = "../../input/grid5000/"
  refapi_hash = load_yaml_file_hierarchy
  count = {}
  total_count = 0

  refapi_hash["sites"].sort.each do |site_uid, site|
    next if options.key?(:sites) && !options[:sites].include?(site_uid)

    site_dead_nodes = get_site_dead_nodes(site_uid, options)

    count[site_uid] = {}

    site["clusters"].sort.each do |cluster_uid, cluster|
      next if options.key?(:clusters) && !options[:clusters].include?(cluster_uid)

      count[site_uid][cluster_uid] = 0

      refnode_uid = nil
      refnode = nil

      cluster["nodes"].each_sort_by_node_uid do |node_uid, node|
        next if node['status'] == 'retired' || site_dead_nodes.include?(node_uid)

        if !refnode
          refnode = node
          refnode_uid = node_uid
          next
        end

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

        total_count += diffs.size
        count[site_uid][cluster_uid] += diffs.size

        # Remove the following line if you want to compare each nodes to the first cluster node
        refnode_uid = node_uid
        refnode = node
      end
    end
  end

  return [total_count, count]
end

def check_cluster_homogeneity(options = {:verbose => false})
  refapi_hash = load_yaml_file_hierarchy
  options[:api] = {}
  conf = RefRepo::Utils.get_api_config
  options[:api][:user] = conf['username']
  options[:api][:pwd] = conf['password']

  verbose = options[:verbose]
  puts "Differences found between successive nodes, per cluster:\n\n"

  total_count, count = cluster_homogeneity(refapi_hash, options)
  puts "\n" if verbose

  puts count.to_yaml unless verbose

  puts "\nUse 'VERBOSE=1' option for details." unless verbose

  return total_count == 0
end
