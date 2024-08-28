# coding: utf-8

require 'refrepo/data_loader'

TRUNK_KINDS = ['router', 'switch', 'backbone'] # how to detect trunk ports in network refapi
KAVLANNGG5K_OPTIONS = [ 'additional_trunk_ports' ] # these options are for us, not for neutron/NGS

def generate_puppet_kavlanngg5k(options)
  gen_kavlanapi_g5k_desc(File.join(options[:output_dir], "platforms/production/modules/generated/files/grid5000/kavlanng/g5k/"), options)
  gen_sites_ngs_device_configs(File.join(options[:output_dir], "platforms/production/generators/kavlanng/kavlanng.yaml"), File.join(options[:output_dir], "platforms/production/modules/generated/files/grid5000/kavlanng/ngs_agent.conf.d"), options)
end

def gen_kavlanapi_g5k_desc(output_path, options)
  puts "KavlanNG: generate g5k network description for kavlan-api"
  puts "  to #{output_path}"
  puts "  for sites #{options[:sites]}"
  refapi = load_data_hierarchy
  refapi.delete_if { |k| k != 'sites' }
  refapi['sites'].delete_if { |s| !options[:sites].include? s }
  refapi['sites'].each do |site_id, site_h|
    if options[:verbose]
      puts "  #{site_id}"
    end
    site_h.delete_if { |k| !['clusters', 'network_equipments', 'servers'].include? k }
    site_h.fetch('clusters', {}).each do |cluster_id, cluster_h|
      if options[:verbose]
        puts "    #{cluster_id}"
      end
      cluster_h.delete_if { |k| k != 'nodes' }
      cluster_h['nodes'].each do |_node_id, node_h|
        node_h.delete_if { |k| k != 'network_adapters' }
        node_h['network_adapters'].delete_if { |na| na.fetch('kavlan') != true }
        node_h['network_adapters'].each do |na|
          na.delete_if { |k| !['interface', 'mounted', 'management', 'device', 'name', 'switch', 'switch_port', 'mac'].include? k }
        end
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
  # save to file, splitted by sites and clusters
  # first clean the site(s) we are generating
  # (only issue: when removing a g5k site, this code cannot guess that
  # a site is not there because it was removed or because generation
  # was not asked for this site, so in this case, it will not remove
  # the generated files for the site, these files need to be removed
  # manually)
  refapi['sites'].each { |site_id, _site_h|
    FileUtils.rm Dir.glob(File.join(output_path, "#{site_id}.json"))
    FileUtils.rm Dir.glob(File.join(output_path, "#{site_id}-*"))
  }
  refapi['sites'].each do |site_id, site_h|
    refapi_site = { 'sites' => { site_id => site_h.select { |k, _v| k != 'clusters' } } }
    File.open(File.join(output_path, "#{site_id}.json"), 'w') do |f|
      f.write(JSON.pretty_generate(refapi_site))
    end
    site_h['clusters'].each do |cluster_id, cluster_h|
      refapi_site_cluster = { 'sites' => { site_id => { 'clusters' => { cluster_id => cluster_h } } } }
      File.open(File.join(output_path, "#{site_id}-#{cluster_id}.json"), 'w') do |f|
        f.write(JSON.pretty_generate(refapi_site_cluster))
      end
    end
  end
end

# compute the port name for NGS ssh commands, based on device,
# linecard, port, using refapi ssh/kavlan/snmp patterns (with
# %LINECARD%, %PORT% substitutions), and interpolating the string for
# ssh_pattern
def get_port_name(_refapi, site_name, device_name, linecard_index, linecard, port_index, port)
  # try different possibilities, by order of precedence
  if port.has_key?('ssh_name')
    return port['ssh_name']
  elsif port.has_key?('snmp_name')
    return port['snmp_name']
  elsif linecard.has_key?('kavlan_pattern')
    return get_port_pattern_subst(linecard['kavlan_pattern'], linecard_index, port_index)
  else
    puts "WARNING #{site_name}/#{device_name}/linecard-#{lc_index}/port-#{port_index}: unable to guess portname, fallback to port's uid: #{port['uid']}"
    return port['uid']
  end
end

# compute the channel name for NGS ssh commands, based on device,
# using refapi channel_ssh_pattern (with %CHANNEL% substitution), and
# interpolating the string
def get_channel_name(_refapi, _site_name, _device_name, channel, channel_name)
  if channel.has_key?('ssh_name')
    return channel['ssh_name']
  else
    return channel_name
  end
end

def gen_sites_ngs_device_configs(input_path, output_path, options)
  puts "KavlanNG: generate sites NGS device configurations"
  puts "  to #{output_path}"
  puts "  based on reference repository and kavlanng configuration in #{input_path}"
  puts "  for sites #{options[:sites]}"
  refapi = load_data_hierarchy
  network_devices_data = YAML::load(File.read(input_path))
  network_devices_data.delete_if { |s| !options[:sites].include? s }

  # match devices in kavlanng conf and in refapi
  network_devices_data.each do |site, site_data|
    if options[:verbose]
      puts "  #{site}"
    end
    File.open(File.join(output_path, "#{site}.conf"), 'w') do |site_ngs_conf|
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
          if options[:verbose]
            if device == refapi_device
              puts "    #{device}"
            else
              puts "    #{device} (alias of #{refapi_device})"
            end
          end
          site_ngs_conf.puts("[genericswitch:#{device}.#{site}.grid5000.fr]")
          device_data.each do |k, v|
            if ! KAVLANNGG5K_OPTIONS.include? k
              site_ngs_conf.puts("#{k} = #{v}")
            end
          end
          site_ngs_conf.puts("ngs_zone = #{site}")
          site_ngs_conf.puts("ngs_network_name_format = kvl-{network_id:.10}")
          site_ngs_conf.puts("ngs_ssh_disabled_algorithms = kex:diffie-hellman-group-exchange-sha1")
          site_ngs_conf.puts("ngs_port_default_vlan = 100")
          site_ngs_conf.puts("ngs_save_configuration = False")
          site_ngs_conf.puts("ngs_manage_vlans = True")
          site_ngs_conf.puts("ngs_physical_networks = g5k, #{site}")

          # trunk ports
          ngs_trunk_ports = []

          # from ports
          if refapi['sites'][site]['network_equipments'][refapi_device].has_key? 'linecards'
            refapi['sites'][site]['network_equipments'][refapi_device]['linecards'].each_with_index do |lc, lc_index|
              if lc.has_key?('ports')
                lc['ports'].each_with_index do |port, port_index|
                  if port.has_key? 'trunk'
                    if port['trunk']
                      portname = get_port_name(refapi, site, refapi_device, lc_index, lc, port_index, port)
                      if options[:verbose]
                        puts "      trunk port on #{site}/#{refapi_device}, kind: #{port['kind']}, name: #{portname}"
                      end
                      ngs_trunk_ports.push portname
                    end
                  elsif port.has_key? 'kind'
                    if TRUNK_KINDS.include? port['kind']
                      portname = get_port_name(refapi, site, refapi_device, lc_index, lc, port_index, port)
                      if options[:verbose]
                        puts "      trunk port on #{site}/#{refapi_device}, kind: #{port['kind']}, name: #{portname}"
                      end
                      ngs_trunk_ports.push portname
                    end
                  end
                end
              end
            end
          end

          # from channels
          if refapi['sites'][site]['network_equipments'][refapi_device].has_key? 'channels'
            refapi['sites'][site]['network_equipments'][refapi_device]['channels'].each do |channelname, channel|
              if channel.has_key? 'trunk'
                if channel['trunk']
                  actual_channel_name = get_channel_name(refapi, site, refapi_device, channel, channelname)
                  if options[:verbose]
                    puts "      trunk channel on #{site}/#{refapi_device}, kind: #{channel['kind']}, name: #{actual_channel_name}"
                  end
                  ngs_trunk_ports.push actual_channel_name
                end
              elsif channel.has_key? 'kind'
                if TRUNK_KINDS.include? channel['kind']
                  actual_channel_name = get_channel_name(refapi, site, refapi_device, channel, channelname)
                  if options[:verbose]
                    puts "      trunk channel on #{site}/#{refapi_device}, kind: #{channel['kind']}, name: #{actual_channel_name}"
                  end
                  ngs_trunk_ports.push actual_channel_name
                end
              end
            end
          end

          # additional trunk ports
          if device_data.has_key? 'additional_trunk_ports'
            device_data['additional_trunk_ports'].each do |additional_trunk_port|
              if options[:verbose]
                puts "      additional trunk port on #{site}/#{device}: #{additional_trunk_port}"
              end
              ngs_trunk_ports.push additional_trunk_port
            end
          end
          site_ngs_conf.puts("ngs_trunk_ports = #{ngs_trunk_ports.join(', ')}")
          site_ngs_conf.puts("")
        end
      end
    end
  end
end
