require 'refrepo/data_loader'
require 'net/http'
require 'peach'
require 'json'
require 'yaml'

def generate_puppet_webfish(options)

    if not options[:conf_dir]
        options[:conf_dir] = "#{options[:output_dir]}/platforms/production/generators/ipmitools/"
    end

    allBmc = check_redfish_availability(3)
    credentials = YAML::load_file(options[:conf_dir] + 'console-password.yaml')
    add_credentials(credentials, allBmc)
    gen_json_files(allBmc, options)

end

def check_redfish_availability(timeout)

    data = load_data_hierarchy
    allBmc = {}
    # allBmc --> hash de hash de tableau de hash 
    data['sites'].peach do |s_uid, d_site|
        allBmc[s_uid] = {}
        p "checking site #{s_uid}"
        d_site['clusters'].peach do |_c_uid, d_cluster|
            d_cluster['nodes'].peach do |n_uid, d_node|
                if d_node['network_adapters'].select{ |na| na['device'] == 'bmc' }.length == 0
                    #estats cluster in toulouse has no bmc
                    next
                end
                url = 'https://'+d_node['network_adapters'].select{ |na| na['device'] == 'bmc' }.first['network_address']

                check_url(url, n_uid, allBmc, 'node', s_uid, timeout)
            end
        end

        d_site['servers'].peach do |srv_uid, d_server|
            if d_server['kind'] == "physical"
                if !d_server['network_adapters'].nil?
                    if !d_server['network_adapters']['bmc'].nil?
                        if !d_server['network_adapters']['bmc']['ip'].nil?
                            url = 'https://'+d_server['network_adapters']['bmc']['ip']

                            check_url(url, srv_uid, allBmc, 'infra', s_uid, timeout)
                        end
                    end
                end
            end
        end
        p "site #{s_uid} done"
    end
    

    return allBmc

end

def check_url(url, uid, allBmc, type, site, timeout)

    uri = URI(url+'/redfish/v1/')

    begin
        req = Net::HTTP::Get.new(uri.path)
        res = Net::HTTP.start(
                uri.host, uri.port, 
                :use_ssl => uri.scheme == 'https', 
                :verify_mode => OpenSSL::SSL::VERIFY_NONE,
                :open_timeout => timeout,
                :read_timeout => timeout) do |https|
            https.request(req)
        end
        allBmc[site][uid] = {
            'url' => url, 
            'node' => type == 'node', 
            'redfish' => res.code.to_i() == 200 ? true : false,
            'error' => nil}
    rescue => error
        allBmc[site][uid] = {
            'url' => url, 
            'node' => type == 'node', 
            'redfish' => false, 
            'error' => error.class}
    end

end

def add_credentials(credentials, allBmc)

    allBmc.peach do |s_site, d_site|
        d_site.peach do |uid, n|
            #si ce n'est pas compatible redfish, on ne store pas
            if !n['redfish'] 
                next
            end 
            # bmc password is global for cluster nodes
            nodeName = n['node'] ? uid.slice(/\w*/) : uid
            begin
                n['login'], n['password'] = credentials[s_site][nodeName].split() 
            rescue NoMethodError
                p(uid + " has no password in list " + s_site)
                n['error'] = "no password defined in console-password.yaml"
            rescue => error
                #p "infra :uid #{uid}, url #{n['url']} mon potentiel password : #{credentials[s_site][uid]}, site #{s_site}, error : #{error.class} error  message: #{error}, nodeName : #{nodeName}"
                n['error'] = error.class
            end
        end
    end

end

def gen_json_files(allBmc, options)

    pretty_dict = {}

    dir = "#{options[:output_dir]}/platforms/production/modules/generated/files/grid5000/webfish" 

    if !Dir.exist?(dir)
        Dir.mkdir(dir)
    end
    actualFile = dir + "/webfish.json"

    allBmc.each do |s_site, _d_array|
        pretty_dict[s_site] = allBmc[s_site].sort_by{|k, _| [k[/(\D+)/, 1], k[/(\d+)/, 1].to_i, k[/-(\d+)/, 1].to_i]}.to_h
    end

    File.open(actualFile, "w") do |f|  
        f.write(JSON.pretty_generate(pretty_dict))
    end
    
end
