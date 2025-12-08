require 'refrepo/data_loader'
require 'net/http'
require 'peach'
require 'json'
require 'yaml'

def generate_puppet_webfish(options)
  options[:conf_dir] = "#{options[:output_dir]}/platforms/production/generators/redfish/" unless options[:conf_dir]
  file = options[:conf_dir] + 'console-password.yaml'
  puts "Writing Webfish configuration files to: #{file}"
  puts "For site(s): #{options[:sites].join(', ')}"
  allBmc = gen_redfish_configuration(options)
  credentials = YAML.load_file(file)
  add_credentials(credentials, allBmc)
  gen_json_files(allBmc, options)
end

def gen_redfish_configuration(options)
  data = load_data_hierarchy
  allBmc = {}
  # allBmc --> hash de hash de tableau de hash
  data['sites'].peach do |s_uid, d_site|
    next unless options[:sites].include?(s_uid)

    allBmc[s_uid] = {}
    p "checking site #{s_uid}"
    d_site['clusters'].peach do |_c_uid, d_cluster|
      next unless d_cluster['redfish']

      d_cluster['nodes'].peach do |n_uid, d_node|
        if d_node['network_adapters'].select { |na| na['device'] == 'bmc' }.length == 0
          # estats cluster in toulouse has no bmc
          next
        end
        next unless d_node['redfish']

        url = 'https://' + d_node['network_adapters'].select do |na|
                             na['device'] == 'bmc'
                           end.first['network_address']
        allBmc[s_uid][n_uid] = {
          'url' => url,
          'node' => true,
          'redfish' => true,
          'error' => nil
        }
      end
    end
    d_site['servers'].peach do |srv_uid, d_server|
      if d_server['kind'] == 'physical'
        next unless d_server['redfish']

        if !d_server['network_adapters'].nil? && !d_server['network_adapters']['bmc'].nil? && !d_server['network_adapters']['bmc']['ip'].nil?
          url = 'https://' + srv_uid + '-bmc.' + s_uid + '.grid5000.fr'
          allBmc[s_uid][srv_uid] = {
            'url' => url,
            'node' => false,
            'redfish' => true,
            'error' => nil
          }
        end
      end
    end
    p "site #{s_uid} done"
  end
  allBmc
end

def add_credentials(credentials, allBmc)
  allBmc.peach do |s_site, d_site|
    d_site.peach do |uid, n|
      # si ce n'est pas compatible redfish, on ne store pas
      next unless n['redfish']

      # bmc password is global for cluster nodes
      nodeName = n['node'] ? uid.slice(/\w*/) : uid
      begin
        n['login'], n['password'] = credentials[s_site][nodeName].split
      rescue NoMethodError
        p(uid + ' has no password in list ' + s_site)
        n['error'] = 'no password defined in console-password.yaml'
      rescue StandardError => e
        n['error'] = e.class
      end
    end
  end
end

def checks_dir_creation(dir)
  Dir.mkdir(dir) unless Dir.exist?(dir)
end

def gen_json_files(allBmc, options)
  actualFile = {}
  dir = "#{options[:output_dir]}/platforms/production/modules/generated/files/grid5000/webfish"
  checks_dir_creation(dir)
  allBmc.sort_by { |s_site, _d_site| s_site }.each do |s_site, _d_array|
    actualFile = allBmc[s_site].sort_by { |k, _| split_cluster_node(k) }.to_h
    siteLocation = dir + '/' + s_site
    checks_dir_creation(siteLocation)
    fileLocation = siteLocation + '/webfish.json'
    File.open(fileLocation, 'w') do |f|
      f.write(JSON.pretty_generate(actualFile))
    end
  end
end
