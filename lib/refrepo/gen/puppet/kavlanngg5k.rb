# coding: utf-8

require 'refrepo/data_loader'
require 'set'

TRUNK_IGNORE_KINDS = [ 'backbone', 'channel' ]
    # the kinds of ports that we ignore for trunks even if they are in
    # trunk mode

TRUNK_CHECK_OTHER_SIDE = [ 'router', 'switch', 'hpcswitch' ]
    # the kind of ports for which we check if 1/ the other side is
    # part of kavlanng config and 2/ if the other side is
    # managed_by_us == true

KAVLANNGG5K_OPTIONS = [ 'additional_trunk_ports', 'blacklist_trunk_ports' ]
    # these options are for us, not for neutron/NGS

def warn(msg)
  puts "WARNING: #{msg}"
end

def error(msg)
  abort "ERROR: #{msg}"
end

# entry point
def generate_puppet_kavlanngg5k(options)
  # Generate a subset of the refapi with only the informations needed
  # for kavlan-api.
  gen_kavlanapi_g5k_desc(File.join(options[:output_dir],
                                   "platforms/production/modules/generated/files/grid5000/kavlanng/g5k/"),
                         options)

  # Generate NGS configurations
  gen_sites_ngs_device_configs(File.join(options[:output_dir],
                                         "platforms/production/generators/kavlanng/kavlanng.yaml"),
                               File.join(options[:output_dir],
                                         "platforms/production/modules/generated/files/grid5000/kavlanng/ngs_agent.conf.d"),
                               options)
end

# Generate a subset of the refapi with only the informations needed
# for kavlan-api to be able to map network interfaces on nodes to
# ports on network devices, in order to set the correct
# binding:profile of neutron ports, that NGS will use to configure the
# network devices.
#
# The generated data is splitted by site and by cluster for two
# reasons: 1/ allow independant modifications to sites/clusters to not
# pollute each others and 2/ to allow distribution between separate
# kavlan-api instances.
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
    if options[:verbose]
      puts "    clusters"
    end
    site_h.fetch('clusters', {}).each do |cluster_id, cluster_h|
      if options[:verbose]
        puts "      #{cluster_id}"
      end
      cluster_h.delete_if { |k| k != 'nodes' }
      cluster_h['nodes'].each do |node_id, node_h|
        node_h.delete_if { |k, _v| k != 'network_adapters' }
        node_h['network_adapters'].delete_if do |na_h|
          if na_h.has_key? 'kavlanng'
            if options[:verbose]
              if not na_h['kavlanng']
                puts "        #{node_id}: remove network_adapter #{na_h['device']} because property kavlanng = #{na_h['kavlanng']}"
              else
                puts "        #{node_id}: keep network_adapter #{na_h['device']} because property kavlanng = #{na_h['kavlanng']}"
              end
            end
            (not na_h['kavlanng'])
          elsif na_h.has_key? 'kavlan'
            # if options[:verbose]
            #   if not na_h['kavlan']
            #     puts "        #{node_id}: remove network_adapter #{na_h['device']} because property kavlan = #{na_h['kavlan']}"
            #   else
            #     puts "        #{node_id}: keep network_adapter #{na_h['device']} because property kavlan = #{na_h['kavlan']}"
            #   end
            # end
            (not na_h['kavlan'])
          else
            if options[:verbose]
              puts "        #{node_id}: remove network_adapter #{na_h['device']} because neither properties kavlanng or kalvan are defined"
            end
            true
          end
        end
        node_h['network_adapters'].each do |na_h|
          na_h.delete_if { |k, _v| !['interface', 'mounted', 'management', 'device', 'name', 'switch', 'switch_port', 'mac'].include? k }
        end
      end
    end
    if options[:verbose]
      puts "    network equipments"
    end
    site_h['network_equipments'].each do |ne_id, ne_h|
      if options[:verbose]
        puts "      #{ne_id}"
      end
      ne_h.delete_if { |k| ! ['ip', 'ip6', 'kind'].include? k }
    end
    routers = site_h['network_equipments'].select { |_ne_id, ne_h| ne_h['kind'] == 'router' }
    if routers.length != 1
      warn "#{site_id} has #{routers.length} routers"
    end
    site_h['servers'].delete_if { |k, _v| k != 'dns' }
    dns_list = site_h['servers'].keys
    if dns_list.length != 1
      warn "#{site_id} has #{dns_list.length} DNS"
    end
    begin
      site_h['servers']['dns'].delete_if { |k, _v| k != 'network_adapters' }
      site_h['servers']['dns']['network_adapters'].delete_if { |k, _v| k != 'default' }
    rescue
      warn "#{site_id} unable to properly clean DNS server entry"
    end
    begin
      dns_ip = site_h['servers']['dns']['network_adapters']['default']['ip']
      if !dns_ip
        warn "#{site_id} unable to get DNS IP address"
      end
    rescue StandardError
      warn "#{site_id} unable to get DNS IP address"
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
    FileUtils.remove_dir(File.join(output_path, site_id), true)
  }
  refapi['sites'].each do |site_id, site_h|
    Dir.mkdir(File.join(output_path, site_id))
    refapi_site = { 'sites' => { site_id => site_h.select { |k, _v| k != 'clusters' } } }
    File.open(File.join(output_path, site_id, "#{site_id}.json"), 'w') do |f|
      f.write(JSON.pretty_generate(refapi_site))
    end
    site_h['clusters'].each do |cluster_id, cluster_h|
      refapi_site_cluster = { 'sites' => { site_id => { 'clusters' => { cluster_id => cluster_h } } } }
      File.open(File.join(output_path, site_id, "#{site_id}-#{cluster_id}.json"), 'w') do |f|
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
    warn "#{site_name}/#{device_name}/linecard-#{lc_index}/port-#{port_index}: unable to guess portname, fallback to port's uid: #{port['uid']}"
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

def get_kavlanng_managed_devices(site, kavlanng_config)
  return kavlanng_config[site].keys
end

# Generate the NGS configuration for all network devices (device name,
# device type, ip address, trunk ports, auth credentials, routing
# config, etc.)
#
# The generated configurations are splitted by site.
def gen_sites_ngs_device_configs(kavlanng_config_path, output_path, options)
  puts "KavlanNG: generate sites NGS device configurations"
  puts "  to #{output_path}"
  puts "  based on reference repository and kavlanng configuration in #{kavlanng_config_path}"
  puts "  for sites #{options[:sites]}"
  refapi = load_data_hierarchy
  kavlanng_config = YAML::load(File.read(kavlanng_config_path))
  generic_config = kavlanng_config['global']
  kavlanng_config.delete('global')
  kavlanng_config.delete_if { |s| !options[:sites].include? s }

  # match devices in kavlanng conf and in refapi
  kavlanng_config.each do |site, site_data|
    if options[:verbose]
      puts "  #{site}"
    end
    File.open(File.join(output_path, "#{site}.conf"), 'w') do |site_ngs_conf|
      site_data.each do |device, device_data|
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
          error "#{site}/#{device} is not in refapi. refapi['sites'][#{site}]['network_equipments'] contains #{refapi['sites'][site]['network_equipments'].keys}"
        else
          if options[:verbose]
            if device == refapi_device
              puts "    #{device}"
            else
              puts "    #{device} (alias of #{refapi_device})"
            end
          end
          site_ngs_conf.puts("[genericswitch:#{device}.#{site}.grid5000.fr]")

          if ! refapi['sites'][site]['network_equipments'][refapi_device].has_key? 'ngs_device_type'
            error "#{site}/#{device} does not have ngs_device_type set in refapi"
          end
          if refapi['sites'][site]['network_equipments'][refapi_device]['kind'] == 'router' && ! refapi['sites'][site]['network_equipments'][refapi_device]['ngs_device_type'].end_with?('_router')
            error "#{site}/#{device} is a router, but its ngs_device_type does not end with '_router'"
          end
          if refapi['sites'][site]['network_equipments'][refapi_device]['kind'] == 'router' && (! refapi['sites'][site]['network_equipments'][refapi_device].has_key? 'ospf_instance_ipv4' or ! refapi['sites'][site]['network_equipments'][refapi_device].has_key? 'ospf_instance_ipv6')
            error "#{site}/#{device} ospf_instance_ipv4 and ospf_instance_ipv6 must be set in refapi for routers"
          end

          site_ngs_conf.puts("ip = #{refapi['sites'][site]['network_equipments'][refapi_device]['ip']}")
          site_ngs_conf.puts("device_type = #{refapi['sites'][site]['network_equipments'][refapi_device]['ngs_device_type']}")
          if refapi['sites'][site]['network_equipments'][refapi_device]['kind'] == 'router'
            site_ngs_conf.puts("ospf_instance_ipv4 = #{refapi['sites'][site]['network_equipments'][refapi_device]['ospf_instance_ipv4']}")
            site_ngs_conf.puts("ospf_instance_ipv6 = #{refapi['sites'][site]['network_equipments'][refapi_device]['ospf_instance_ipv6']}")
          end

          device_data.each do |k, v|
            if ! KAVLANNGG5K_OPTIONS.include? k
              site_ngs_conf.puts("#{k} = #{v}")
            end
          end

          generic_config.each do |k, v|
            site_ngs_conf.puts("#{k} = #{v}")
          end

          site_ngs_conf.puts("ngs_physical_networks = #{site}")

          # trunk ports
          ngs_trunk_ports = []

          # from ports
          if refapi['sites'][site]['network_equipments'][refapi_device].has_key? 'linecards'
            refapi['sites'][site]['network_equipments'][refapi_device]['linecards'].each_with_index do |lc, lc_index|
              if lc.has_key?('ports')
                lc['ports'].each_with_index do |port, port_index|
                  if port.has_key? 'switchport_mode'
                    if port['switchport_mode'] == 'trunk'
                      portname = get_port_name(refapi, site, refapi_device, lc_index, lc, port_index, port)
                      other_side = port['uid']
                      if not TRUNK_IGNORE_KINDS.include?(port['kind'])
                        if TRUNK_CHECK_OTHER_SIDE.include?(port['kind'])
                          if not refapi['sites'][site]['network_equipments'][other_side]['managed_by_us']
                            if options[:verbose]
                              puts "      ignore trunk port #{site} - #{refapi_device} - #{portname} to #{other_side} (kind: #{port['kind']}), reason: the other side is not managed_by_us"
                            end
                          elsif not get_kavlanng_managed_devices(site, kavlanng_config).include? other_side
                            if options[:verbose]
                              puts "      ignore trunk port #{site} - #{refapi_device} - #{portname} to #{other_side} (kind: #{port['kind']}), reason: the other side is not configured in kavlanng"
                            end
                          else
                            if options[:verbose]
                              puts "      trunk port #{site} - #{refapi_device} - #{portname} to #{other_side} (kind: #{port['kind']})"
                            end
                            ngs_trunk_ports.push portname
                          end
                        else
                          if options[:verbose]
                            puts "      trunk port #{site} - #{refapi_device} - #{portname} to #{other_side} (kind: #{port['kind']})"
                          end
                          ngs_trunk_ports.push portname
                        end
                      else
                        if options[:verbose]
                          puts "      ignore trunk port #{site} - #{refapi_device} - #{portname} to #{other_side}, reason: we ignore ports with kind: #{port['kind']}"
                        end
                      end
                    end
                  end
                end
              end
            end
          end

          # from channels
          if refapi['sites'][site]['network_equipments'][refapi_device].has_key? 'channels'
            refapi['sites'][site]['network_equipments'][refapi_device]['channels'].each do |channelname, channel|
              if channel.has_key? 'switchport_mode'
                if channel['switchport_mode'] == 'trunk'
                  actual_channel_name = get_channel_name(refapi, site, refapi_device, channel, channelname)
                  other_side = channel['uid']
                  if (not channel.has_key? 'kind') or (not TRUNK_IGNORE_KINDS.include?(channel['kind']))
                    if channel.has_key? 'kind' and TRUNK_CHECK_OTHER_SIDE.include?(channel['kind'])
                      if not refapi['sites'][site]['network_equipments'][other_side]['managed_by_us']
                        if options[:verbose]
                          puts "      ignore trunk channel #{site} - #{refapi_device} - #{channelname} to #{other_side} (kind: #{channel['kind']}), reason: the other side is not managed_by_us"
                        end
                      elsif not get_kavlanng_managed_devices(site, kavlanng_config).include? other_side
                        if options[:verbose]
                          puts "      ignore trunk channel #{site} - #{refapi_device} - #{channelname} to #{other_side} (kind: #{channel['kind']}), reason: the other side is not configured in kavlanng"
                        end
                      else
                        if options[:verbose]
                          puts "      trunk channel #{site} - #{refapi_device} - #{channelname} to #{other_side} (kind: #{channel['kind']})"
                        end
                        ngs_trunk_ports.push actual_channel_name
                      end
                    else
                      if options[:verbose]
                        puts "      trunk channel #{site} - #{refapi_device} - #{channel_name} to #{other_side} (kind: #{channel['kind']})"
                      end
                      ngs_trunk_ports.push actual_channel_name
                    end
                  else
                    if options[:verbose]
                      puts "      ignore trunk channel #{site} - #{refapi_device} - #{channel_name} to #{other_side}, reason: we ignore channels with kind: #{channel['kind']}"
                    end
                  end
                end
              end
            end
          end

          # custom trunk ports from kavlanng config
          if device_data.has_key? 'additional_trunk_ports'
            device_data['additional_trunk_ports'].each do |additional_trunk_port|
              if options[:verbose]
                puts "      additional trunk port on #{site}/#{device}: #{additional_trunk_port}"
              end
              ngs_trunk_ports.push additional_trunk_port
            end
          end
          if device_data.has_key? 'blacklist_trunk_ports'
            device_data['blacklist_trunk_ports'].each do |blacklist_trunk_port|
              if options[:verbose]
                puts "      blacklist trunk port on #{site}/#{device}: #{blacklist_trunk_port}"
              end
              ngs_trunk_ports.delete_if { |p| p == blacklist_trunk_port }
            end
          end

          site_ngs_conf.puts("ngs_trunk_ports = #{ngs_trunk_ports.join(', ')}")
          site_ngs_conf.puts("")
        end
      end
    end
  end
end
