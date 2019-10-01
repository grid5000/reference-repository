# coding: utf-8

require 'refrepo/gen/oar-properties'
require 'refrepo/data_loader'

class OarPropertiesGenerator < WikiGenerator

  def initialize(page_name)
    super(page_name)
  end

  #Static information about properties that cannot be infered from ref-api data
  @@properties = {
    "max_walltime" => {
      "description" => "Maximum walltime in seconds allowed on this node (for the production queue only)"
    },
    "cluster_priority" => {
      "description" => "The priority of this resource for job scheduling"
    },
    "besteffort" => {
      "description" => "Can the resource be reserved in besteffort mode ?",
      "value_type" => "Boolean"
    },
    "deploy" => {
      "description" => "Can the resource be used for a deployment ?",
      "value_type" => "Boolean"
    },
    "virtual" => {
      "description" => "Node virtualization capacity"
    },
    "production" => {
      "description" => "Is this resource available in production queue ?",
      "value_type" => "Boolean"
    },
    "cluster" => {
      "description" => "The name of the cluster the resource is part of"
    },
    "core" => {
      "description" => "The ID of the CPU core the resource is part of. The unique scope is the OAR server.",
      "possible_values" => "1, 2, 3, ..."
    },
    "cpu" => {
      "description" => "The ID of the CPU the resource is part of. The unique scope is the OAR server. ",
      "possible_values" => "1, 2, 3, ..."
    },
    "gpu" => {
      "description" => "The ID of the GPU the resource is part of. The unique scope is the OAR server. ",
      "possible_values" => "1, 2, 3, ..."
    },
    "host" => {
      "description" => "A user-friendly name for the network_address property",
      "possible_values" => "dahu-1.grenoble.grid5000.fr, ..."
    },
    "ip" => {
      "description" => "The IPv4 address of the node the resource is part of"
    },
    "network_address" => {
      "description" => "The full hostname of the node the resource is part of",
      "possible_values" => "dahu-1.grenoble.grid5000.fr, ..."
    },
    "switch" => {
      "description" => "On what switch the resource is directly connected ?"
    },
    "nodemodel" => {
      "description" => "The type of the chassis"
    },
    "cpuarch" => {
      "description" => "What CPU architecture resource's CPU is member of ?"
    },
    "cpucore" => {
      "description" => "The number of core per CPU"
    },
    "cputype" => {
      "description" => "What processor's family resource's CPU is member of"
    },
    "cpufreq" => {
      "description" => "The frequency in GHz of resource's CPU"
    },
    # "cpucount" => { #Unused ?
    #   "description" => "The number of CPUs"
    # },
    "eth_count" => {
      "description" => "The number of Ethernet interface the node has"
    },
    "eth_rate" => {
      "description" => "the maximum rate of connected network interfaces in Gbps"
    },
    "ib" => {
      "description" => "The technology of the Infiniband interface"
    },
    "ib_count" => {
      "description" => "The number of Infiniband interfaces available"
    },
    "ib_rate" => {
      "description" => "The rate of the connected Infiniband interface in Gbps"
    },
    "opa" => {
      "description" => "Whether an Omni-Path interface is available"
    },
    "opa_count" => {
      "description" => "The number of Omni-Path interfaces available"
    },
    "opa_rate" => {
      "description" => "The rate of the connected Omni-Path interface in Gbps"
    },
    "myri" => {
      "description" => "The type of Myrinet interfaces available"
    },
    "myri_count" => {
      "description" => "The number of Myrinet interfaces available"
    },
    "myri_rate" => {
      "description" => "The rate of the connected Myrinet interface in Gbps"
    },
    "disktype" => {
      "description" => "What disk's interface family node's disk is member of ?"
    },
    "disk_reservation_count" => {
      "description" => "The number of reservable disks"
    },
    "memcpu" => {
      "description" => "The amount of memory in MB per CPU"
    },
    "memcore" => {
      "description" => "The amount of memory in MB per CPU core"
    },
    "memnode" => {
      "description" => "The total amount of memory in MB of the node"
    },
    "gpu_model" => {
      "description" => "The type of GPU available"
    },
    "gpu_count" => {
      "description" => "The number of GPU cards available"
    },
    "wattmeter" => {
      "description" => "The type of wattmeter available"
    },
    "mic" => {
      "description" => "Intel many integrated core architecture support",
      "value_type" => "Boolean"
    }
  }

  #Group properties by categories
  @@categories = {
    "Job-related properties" => ["besteffort", "deploy", "production", "cluster_priority", "max_walltime"],
    "Hierarchy" => ["cluster", "cpu", "core", "host", "network_address", "ip", "switch"],
    "Hardware" => ["gpu_model", "gpu_count", "memnode", "memcore", "memcpu", "disktype", "disk_reservation_count", "myri_rate", "myri_count", "myri", "ib_rate", "ib_count", "ib", "opa", "opa_rate", "opa_count", "eth_rate", "eth_count", "cpufreq", "cputype", "cpucore", "cpuarch", "virtual", "mic"],
    "Miscellaneous" => ["wattmeter", "nodemodel"]
  }

  #Existing properties that won't be documented
  @@ignored_properties = ["maintenance", "state", "ip_virtual"]

  def get_nodes_properties(_site_uid, site)
    properties = {}
    site['clusters'].sort.to_h.each do |cluster_uid, cluster|
      cluster['nodes'].sort.to_h.each do |node_uid, node|
        begin
          properties[node_uid] = get_ref_node_properties_internal(cluster_uid, cluster, node_uid, node)
        rescue MissingProperty => e
          puts "Error while processing node #{node_uid}: #{e}"
        end
      end
    end
    return properties
  end

  def get_value_type(prop, values)
    if (@@properties[prop]["value_type"])
      return @@properties[prop]["value_type"]
    end
    if (!values.empty?)
      case values[0].class.name
      when "Fixnum", "Numeric", "Integer"
        return "Integer"
      when "TrueClass", "FalseClass"
        return "Boolean"
      end
    end
    "String"
  end

  def generate_content
    refapi = load_data_hierarchy
    #Properties generated from oar-properties generator
    props = {}
    G5K::SITES.each{ |site_uid|
      props[site_uid] = get_nodes_properties(site_uid, refapi["sites"][site_uid])
    }

    #Compiled properties used to generate page
    oar_properties = {}
    props.sort.to_h.each { |site, site_props|
      site_props.sort.to_h.each { |node_uid, node_props|
        node_props.sort.to_h.each { |property, value|
          next if @@ignored_properties.include?(property)

          oar_properties[property] ||= {}
          oar_properties[property]["values"] ||= []
          oar_properties[property]["values"] << value unless value.nil?
          oar_properties[property]["values"].uniq!
          oar_properties[property]["values"].sort!{ |a, b|
            (a && a.to_s || "") <=> (b && b.to_s || "")
          }
        }
      }
    }
    oar_properties.sort.to_h.each { |prop, prop_hash|
      prop_hash["values"].sort!
      if (prop_hash["values"].length > 20)
        #Limit possible values to 20 elements and mark the list as truncated
        prop_hash["values"].slice!(0...-20)
        prop_hash["values"].push("...")
      end
      @@properties[prop]["possible_values"] ||= prop_hash["values"].join(", ")
    }

    @generated_content = "{{Portal|User}}\nProperties on resources managed by OAR allow users to select them according to their experiment's characteristics." + MW::LINE_FEED
    @generated_content += MW::heading("OAR Properties", 1) + MW::LINE_FEED

    @@categories.sort.to_h.each { |cat, cat_properties|
      @generated_content += MW::heading(cat, 2) + MW::LINE_FEED
      cat_properties.sort.each{ |property|
        values = oar_properties[property]["values"] rescue []
        @generated_content += MW::heading(MW::code(property), 3) + MW::LINE_FEED
        @generated_content += @@properties[property]["description"] + MW::LINE_FEED
        value_type = get_value_type(property, values)
        @generated_content += MW::LIST_ITEM + " Value type: " + MW::code(value_type) + MW::LINE_FEED
        @generated_content += MW::LIST_ITEM + " Possible values: " + MW::code(@@properties[property]["possible_values"]) + MW::LINE_FEED
      }
    }
    @generated_content += MW.italic(MW.small(generated_date_string))
    @generated_content += MW::LINE_FEED
  end
end

if __FILE__ == $0
  generator = OarPropertiesGenerator.new("OAR_Properties")

  options = WikiGenerator::parse_options
  if (options)
    ret = 2
    begin
      ret = generator.exec(options)
    rescue MediawikiApi::ApiError => e
      puts e, e.backtrace
      ret = 3
    rescue StandardError => e
      puts e, e.backtrace
      ret = 4
    ensure
      exit(ret)
    end
  end
end
