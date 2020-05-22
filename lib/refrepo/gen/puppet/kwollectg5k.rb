require 'refrepo/hash/hash'
require 'erb'

def generate_puppet_kwollectg5k(options)

  puts "Writing kwollect configuration files to: #{options[:output_dir]}"
  puts "Using configuration directory: #{options[:conf_dir]}"
  puts "For site(s): #{options[:sites].join(', ')}"

  if not options[:conf_dir]
    options[:conf_dir] = "#{options[:output_dir]}/platforms/production/generators/ipmitools/"
  end
  if not Pathname("#{options[:conf_dir]}/console-password.yaml").exist?
    puts "Warning: No #{options[:conf_dir]}/console-password.yaml file found"
    credentials = {}
  else
    credentials = YAML::load_file("#{options[:conf_dir]}/console-password.yaml")
  end

  refapi = load_data_hierarchy

  refapi['sites'].each { |site_uid, site|

    next unless options[:sites].include?(site_uid)

    # Metrics configuration for each node
    site['clusters'].sort.each { |cluster_uid, cluster|
      cluster['nodes'].each_sort_by_node_uid { |node_uid, node|

        ipmi_credentials = credentials.fetch(site_uid, {}).fetch(cluster_uid, "").split(" ")
        ipmi_credentials.map! { |s| ERB::Util.url_encode(s) }
        ipmi_credentials = ipmi_credentials.join(":")

        output = ERB.new(File.read(File.expand_path('templates/kwollect-node.erb', File.dirname(__FILE__))), nil, '-').result(binding)
        output_file = Pathname("#{options[:output_dir]}//platforms/production/modules/generated/files/grid5000/kwollect/#{site_uid}/#{node_uid}.conf")
        output_file.dirname.mkpath()
        File.write(output_file, output)
      }
    }

    # Metrics configuration for network device
    site['network_equipments'].each { |neteq_uid, neteq|

      output = ERB.new(File.read(File.expand_path('templates/kwollect-network.erb', File.dirname(__FILE__))), nil, '-').result(binding)
      output_file = Pathname("#{options[:output_dir]}//platforms/production/modules/generated/files/grid5000/kwollect/#{site_uid}/#{neteq_uid}.conf")
      output_file.dirname.mkpath()
      File.write(output_file, output)
    }

    # Metrics configuration for PDU
    ## First, parse all PDU to find nodes that use two PSUs
    ports_by_node = {}
    site.fetch('pdus', {}).each { |pdu_uid, pdu|
      pdu.fetch('metrics', []).each {|metric|
        next if metric['source']['protocol'] != 'snmp'
        if metric['source']['id'].include?('%PORT%')
          pdu['ports'].each {|port_uid, node_uid|
            if not ports_by_node.has_key?(node_uid)
              ports_by_node[node_uid] = []
            end
            ports_by_node[node_uid] << "#{pdu_uid}-port-#{port_uid}"
          }
        end
      }
    }
    ## Then, write PDU metrics config
    site.fetch('pdus', {}).each { |pdu_uid, pdu|

      output = ERB.new(File.read(File.expand_path('templates/kwollect-pdu.erb', File.dirname(__FILE__))), nil, '-').result(binding)
      output_file = Pathname("#{options[:output_dir]}//platforms/production/modules/generated/files/grid5000/kwollect/#{site_uid}/#{pdu_uid}.conf")
      output_file.dirname.mkpath()
      File.write(output_file, output)
    }

    # Wattmetre mapping configuration
    wattmetre_port_per_node = {}
    site.fetch('pdus', {}).each { |pdu_uid, pdu|

      next if pdu.fetch('metrics', []).none?{|metric| metric['source']['protocol'] == 'wattmetre'}

      pdu.fetch('ports', {}).each {|port, node|
        if not wattmetre_port_per_node.key?(node)
          wattmetre_port_per_node[node] = []
        end
        wattmetre_port_per_node[node] << "#{pdu_uid}-port#{port}"
      }
    }
    if not wattmetre_port_per_node.empty?
      output = ERB.new(File.read(File.expand_path('templates/kwollect-wattmetre-mapping.erb', File.dirname(__FILE__))), nil, '-').result(binding)
      output_file = Pathname("#{options[:output_dir]}//platforms/production/modules/generated/files/grid5000/kwollect-wattmetre/#{site_uid}/wattmetre-mapping.conf")
      output_file.dirname.mkpath()
      File.write(output_file, output)
    end
  }
end
