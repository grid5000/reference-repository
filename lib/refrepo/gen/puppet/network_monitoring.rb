# add network_monitoring on supervision.site.grid5000.fr.yaml on hiera
#

NETWORK_EQUIPMENTS_BLACKLIST = [
  'swx1nef',
  'swy1nef',
  'sw-aci-333',
]

def generate_puppet_network_monitoring(options)

  refapi = load_data_hierarchy

  sites = options[:sites]
  out = options[:output_dir]

  sites.each do |s|
    net_eqs = refapi['sites'][s]['network_equipments']
    hiera_file = "#{out}/platforms/production/hieradata/clients/supervision2.#{s}.grid5000.fr.yaml"
    unless File.exist?(hiera_file)
      RefRepo::Utils.warn_or_abort_partial_site("Warning: missing file in hieradata: #{hiera_file}.")
      next
    end
    hiera_yaml = YAML.load_file(hiera_file)

    snmp_hosts = hiera_yaml['grid5000::munin::snmp::hosts'] || []
    net_hosts = hiera_yaml['grid5000::icinga::network::hosts'] || []
    admin_hosts = hiera_yaml['grid5000::icinga::network::admin_hosts'] || []

    net_eqs.each do |eq_name, eq_v|
      next if NETWORK_EQUIPMENTS_BLACKLIST.include?(eq_name)

      fqdn_eq_name = "#{eq_name}.#{s}.grid5000.fr"

      # do not apply to HPC switch
      next if eq_v['kind'] == 'hpcswitch'
      # do not apply to equipment we do not manage
      next if !eq_v['managed_by_us']

      snmp_hosts << fqdn_eq_name unless
        snmp_hosts.find { |i| i == fqdn_eq_name }

      net_hosts_eq = net_hosts.select { |i| i['name'] == fqdn_eq_name }

      if net_hosts_eq.length.zero?
        net_hosts << {
          'name' => fqdn_eq_name,
          'address' => eq_v['ip'],
          'interfaces' => [],
          'has_ospf' => eq_v['kind'] == 'router'
        }
        net_hosts_eq = net_hosts.find { |i| i['name'] == fqdn_eq_name }

      elsif net_hosts_eq.length == 1
        net_hosts_eq = net_hosts_eq.first
      else
        net_hosts_eq = net_hosts_eq.first
        puts "ERROR: multiple entry for #{fqdn_eq_name} in hiera"
      end

      net_hosts_eq['interfaces'] ||= []

      eq_v['linecards'].each do |l|
        next if l == {}

        l['ports'].each do |p|
          next if p == {}
          # bug 15513 : We don't want to monitor bmc traffic until supervision machine are dimensioned for it
          next if p['uid'].include?('bmc')

          next unless %w[other switch router server channel backbone].include?(p['kind'])

          port_name = p['snmp_name']
          next if net_hosts_eq['interfaces'].find { |i| i['name'] == port_name }

          sw = "#{eq_v['channels'][p['uid']]['uid']} " if p['kind'] == 'channel'

          net_hosts_eq['interfaces'] << {
            'name' => port_name,
            'description' => "Uplink #{sw}#{p['uid']}"
          }
        end
      end

      next unless eq_v['channels']
      eq_v['channels'].each do |c_name, c_v|
        next if net_hosts_eq['interfaces'].find { |i| i['name'] == c_name }

        net_hosts_eq['interfaces'] << {
          'name' => c_name,
          'description' => "LACP #{c_v['uid']}"
        }
      end
    end
    hiera_yaml['grid5000::munin::snmp::hosts'] = snmp_hosts
    hiera_yaml['grid5000::icinga::network::hosts'] = net_hosts
    hiera_yaml['grid5000::icinga::network::admin_hosts'] = admin_hosts
    IO.write(hiera_file, YAML.dump(hiera_yaml))
  end
end
