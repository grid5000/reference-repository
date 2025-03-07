# This script checks the cluster homogeneity

require 'hashdiff'

def global_ignore_keys

  #
  # Global ignore keys
  #

  ignore_keys = %w(
    ~chassis.serial
    ~chassis.manufactured_at
    ~chassis.warranty_end

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
    ~network_adapters.ib2.mac
    ~network_adapters.ib3.mac
    ~network_adapters.ibs1.mac

    ~pdu
    ~pdu.port
    ~pdu.uid
    ~pdu[0]
    ~pdu[1]
    ~pdu[2]
    ~pdu[3]
    ~pdu[4]
    ~pdu[5]
    ~pdu[6]
    ~pdu[7]

    ~nodeset

    ~supported_job_types.max_walltime

    ~mic.ip
    ~mic.mac

    ~uid

    +status
    -status
  )

  ignore_netkeys = <<-eos
    ~network_adapters.eth.ip
    -network_adapters.eth.ip
    ~network_adapters.eth.ip6
    -network_adapters.eth.ip6
    ~network_adapters.eth.mac
    ~network_adapters.eth.network_address
    ~network_adapters.eth.switch
    ~network_adapters.eth.switch_port
eos

  ignore_regex = [
    ['~', /storage_devices\..*\.by_id/],
    ['~', /\.*fpga\.*/],
  ]

  (0..7).each { |eth|
    keys = ignore_netkeys.gsub('.eth.', ".eth#{eth}.").gsub("\n", " ").split(" ")
    ignore_keys.push(* keys)

    (1..21).each { |kavlan|
      ignore_keys << "~kavlan.eth#{eth}.kavlan-#{kavlan}"
      ignore_keys << "~kavlan6.eth#{eth}.kavlan-#{kavlan}"
    }
  }

  ignore_ibkeys = <<-eos
    ~network_adapters.IB_IF.guid
    ~network_adapters.IB_IF.hwid
    ~network_adapters.IB_IF.ip
    ~network_adapters.IB_IF.ip6
    ~network_adapters.IB_IF.line_card
    ~network_adapters.IB_IF.position
    ~network_adapters.IB_IF.network_address
    +network_adapters.IB_IF.version
eos

  ib_interfaces = [
    'ib0',
    'ib1',
    'ib2',
    'ib3',
    'ib0.8100',
    'ibs1'
  ]

  ib_interfaces.each { |ib_if|
    keys = ignore_ibkeys.gsub('IB_IF', "#{ib_if}").gsub("\n", " ").split(" ")
    ignore_keys.push(* keys)
  }
  return [ignore_keys, ignore_regex]
end

def cluster_ignore_keys(filename)
  file_hash = YAML::load(ERB.new(File.read(filename)).result(binding))
  file_hash.expand_square_brackets() if file_hash
  return file_hash
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

  ignore_keys, ignore_regex  = global_ignore_keys()
  cignore_keys = cluster_ignore_keys(File.expand_path("data/homogeneity.yaml.erb", File.dirname(__FILE__)))

  count = {}
  total_count = 0

  refapi_hash["sites"].sort.each do |site_uid, site|
    next if options.key?(:sites) && !options[:sites].include?(site_uid)

    count[site_uid] = {}

    site.fetch("clusters", {}).sort.each do |cluster_uid, cluster|
      next if options.key?(:clusters) &&
        !(options[:clusters].include?(cluster_uid) || options[:clusters].empty?)
      count[site_uid][cluster_uid] = 0

      refnode_uid = nil
      refnode = nil

      cluster["nodes"].each_sort_by_node_uid do |node_uid, node|
        next if node['status'] == 'retired'

        if !refnode
          refnode = node
          refnode_uid = node_uid
          next
        end

        diffs = Hashdiff.diff(refnode, node)

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

        not_found_keys = []
        if !ikeys.nil?
          ikeys.each do |key|
            diff = diffs.select {|entry| entry[0] + entry[1] == key}.first
            if diff.nil? 
              not_found_keys << key
              total_count += 1
              count[site_uid][cluster_uid] += 1
            else
              diffs.delete(diff)
            end
          end
        end

        diffs.clone.each do |diff|
          if ignore_keys.include?(diff[0] + diff[1])
            diffs.delete(diff)
            next
          end

          ignore_regex.each do |e|
            if e[0] == diff[0] && e[1].match(diff[1])
              diffs.delete(diff)
              break
            end
          end
        end

        if verbose && !diffs.empty?
          puts "Differences between #{refnode_uid} and #{node_uid}:"
          pp diffs
        end

        if verbose && !not_found_keys.empty?
          puts "Unsatisfied homogeneity exceptions between #{refnode_uid} and #{node_uid}: "
          not_found_keys.each do |key|
            puts "\t#{key}"
          end
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
  total_count, count = cluster_homogeneity(refapi_hash, options)
  puts "\n" if verbose

  unless verbose
    count.each_pair do |site, v|
      next if v.values.select { |c| c != 0 }.empty?
      puts "#{site} ..."
      v.each_pair do |cluster, c|
        next if c == 0
        puts "  #{cluster}: #{c}"
      end
    end
  end

  if total_count == 0
    puts "OK"
    return true
  else
    puts "Use 'VERBOSE=1' option for details." unless verbose
    return false
  end
end
