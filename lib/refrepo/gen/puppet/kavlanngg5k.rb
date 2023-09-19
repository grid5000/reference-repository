# coding: utf-8

require 'refrepo/data_loader'

TRUNK_KINDS = ['router', 'switch', 'backbone']
KAVLANNGG5K_OPTIONS = [ 'additional_trunk_ports' ]

def generate_puppet_kavlanngg5k(options)
  gen_kavlanapi_g5k_desc("#{options[:output_dir]}/platforms/production/modules/generated/files/grid5000/kavlanng/g5k.json")
  gen_ngs_conf("#{options[:output_dir]}/platforms/production/generators/kavlanng/kavlanng.yaml", "#{options[:output_dir]}/platforms/production/modules/generated/files/grid5000/kavlanng/ngs_devices")
end

def gen_kavlanapi_g5k_desc(output_path)
  puts "KavlanNG: generate g5k network description for kavlan-api in #{output_path}"
  refapi = load_data_hierarchy
  refapi.delete_if { |k| k != 'sites' }
  refapi['sites'].each do |site_id, site_h|
    # puts "  #{site_id}"
    site_h.delete_if { |k| !['clusters', 'network_equipments', 'servers'].include? k }
    site_h.fetch('clusters', {}).each do |_cluster_id, cluster_h|
      # puts "    #{_cluster_id}"
      cluster_h.delete_if { |k| k != 'nodes' }
      cluster_h['nodes'].each do |_node_id, node_h|
        node_h.delete_if { |k| k != 'network_adapters' }
      end
    end
    site_h['network_equipments'].delete_if { |_k, v| v['kind'] != 'router' }
    routers = site_h['network_equipments'].keys
    if routers.length != 1
      puts "ERROR: #{site_id} has #{routers.length} routers"
    end
    gw = routers[0]
    site_h['network_equipments'][gw].delete_if { |k| ! ['ip', 'ip6', 'kind'].include? k }
    site_h['servers'].delete_if { |k, _v| k != 'dns' }
    dns_list = site_h['servers'].keys
    if dns_list.length != 1
      puts "ERROR: #{site_id} has #{dns_list.length} DNS"
    end
    begin
      site_h['servers']['dns'].delete_if { |k, _v| k != 'network_adapters' }
      site_h['servers']['dns']['network_adapters'].delete_if { |k, _v| k != 'default' }
    rescue
      puts "ERROR: #{site_id} unable to properly clean DNS server entry"
    end
    begin
      dns_ip = site_h['servers']['dns']['network_adapters']['default']['ip']
      if !dns_ip
        puts "ERROR: #{site_id} unable to get DNS IP address"
      end
    rescue StandardError
      puts "ERROR: #{site_id} unable to get DNS IP address"
    end
  end
  # consistent order
  refapi['sites'] = refapi['sites'].sort_by { |site_id, _site_h| site_id }.to_h
  refapi['sites'].each { |site_id, site_h|
    site_h['clusters'] = site_h.fetch('clusters', {}).sort_by { |cluster_id, _cluster_h| cluster_id }.to_h
    site_h['clusters'].each { |_cluster_id, cluster_h|
      cluster_h['nodes'] = cluster_h['nodes'].sort_by { |node_id, _node_h| node_id[/[^-]+-(\d+)/, 1].to_i }.to_h
    }
    refapi['sites'][site_id] = site_h.sort_by { |key| key}.to_h
  }
  output_file = File.new(output_path, 'w')
  output_file.write(JSON.pretty_generate(refapi))
end

def get_port_name(port_index, port, linecard_index, linecard)
  pattern = nil
  if linecard.has_key?('kavlan_pattern')
    pattern = linecard['kavlan_pattern']
    #pattern_source = "linecard kavlan pattern"
  end
  if port.has_key?('kavlan_pattern')
    pattern = port['kavlan_pattern']
    #pattern_source = "port kavlan pattern"
  end
  if port.has_key?('snmp_pattern')
    pattern = port['snmp_pattern']
    #pattern_source = "port snmp pattern"
  end
  if port.has_key?('snmp_name')
    pattern = port['snmp_name']
    #pattern_source = "port snmp name"
  end
  if pattern
    port_name = pattern.sub("%LINECARD%",linecard_index.to_s).sub("%PORT%",port_index.to_s)
    return port_name
  else
    return nil
  end
end

def gen_ngs_conf(input_path, output_path)
  puts "KavlanNG: generate NGS device configurations in #{output_path} based on reference repository and kavlanng configuration in #{input_path}"
  refapi = load_data_hierarchy
  network_devices_data = YAML::load(File.read(input_path))
  File.open(output_path, 'w') do |ngs_conf|
    network_devices_data.each do |site, site_data|
      #puts "  #{site}"
      site_data['devices'].each do |device, device_data|
        refapi_device = nil
        if refapi['sites'][site]['network_equipments'].has_key? device
          refapi_device = device
        else
          # search aliases
          refapi['sites'][site]['network_equipments'].each do |ne_id, ne|
            if ne.has_key? 'alias'
              ne['alias'].each do |al|
                if al['name'] == device
                  refapi_device = ne_id
                end
              end
            end
          end
        end
        if ! refapi_device
          puts "ERROR #{site}/#{device} is not in refapi. refapi['sites'][#{site}]['network_equipments'] contains #{refapi['sites'][site]['network_equipments'].keys}"
        else
          if device == refapi_device
            # puts "    #{device}"
          else
            # puts "    #{device} (alias of #{refapi_device})"
          end
          ngs_conf.puts("[genericswitch:#{device}.#{site}.grid5000.fr]")
          device_data.each do |k, v|
            if ! KAVLANNGG5K_OPTIONS.include? k
              ngs_conf.puts("#{k} = #{v}")
            end
          end
          ngs_conf.puts("ngs_zone = #{site}")
          ngs_conf.puts("ngs_network_name_format = kavlan-{network_id}")
          ngs_conf.puts("ngs_ssh_disabled_algorithms = kex:diffie-hellman-group-exchange-sha1")
          ngs_conf.puts("ngs_port_default_vlan = 100")
          ngs_conf.puts("ngs_save_configuration = False")
          ngs_conf.puts("#ngs_max_connections = 4")
          ngs_conf.puts("#ngs_batch_requests = True")
          ngs_conf.puts("ngs_manage_vlans = True")
          ngs_trunk_ports = []
          if refapi['sites'][site]['network_equipments'][refapi_device].has_key? 'linecards'
            refapi['sites'][site]['network_equipments'][refapi_device]['linecards'].each_with_index do |lc, lc_index|
              if lc.has_key?('ports')
                lc['ports'].each_with_index do |port, port_index|
                  if port.has_key? 'kind'
                    if TRUNK_KINDS.include? port['kind']
                      portname = get_port_name(port_index, port, lc_index, lc)
                      if not portname
                        puts "ERROR #{site}/#{refapi_device}/linecard-#{lc_index}/port-#{port_index}: unable to guess portname"
                      else
                        #puts "      trunk port on #{site}/#{refapi_device}, kind: #{port['kind']}, name: #{portname}"
                        ngs_trunk_ports.push portname
                      end
                    end
                  end
                end
              end
            end
          end
          if refapi['sites'][site]['network_equipments'][refapi_device].has_key? 'channels'
            refapi['sites'][site]['network_equipments'][refapi_device]['channels'].each do |channelname, channel|
              if channel.has_key? 'kind'
                if TRUNK_KINDS.include? channel['kind']
                  # puts "      trunk channel on #{site}/#{refapi_device}, kind: #{channel['kind']}, name: #{channelname}"
                  ngs_trunk_ports.push channelname
                end
              end
            end
          end
          if device_data.has_key? 'additional_trunk_ports'
            device_data['additional_trunk_ports'].each do |additional_trunk_port|
              # puts "      additional trunk port on #{site}/#{device}: #{additional_trunk_port}"
              ngs_trunk_ports.push additional_trunk_port
            end
          end
          ngs_conf.puts("ngs_trunk_ports = #{ngs_trunk_ports.join(', ')}")
          ngs_conf.puts("")
        end
      end
    end
  end
end
