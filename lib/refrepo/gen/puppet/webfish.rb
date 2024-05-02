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

    if !allBmc.has_key?(site)
        allBmc.store(site, [])
    end

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
        if res.code.to_i() == 200
            allBmc[site] << {'uid' => uid, 'url' => url, 'node' => type == 'node', 'redfish' => true}
        else
            allBmc[site] << {'uid' => uid, 'url' => url, 'node' => type == 'node', 'redfish' => false}
        end
    rescue => error
        allBmc[site] << {'uid' => uid, 'url' => url, 'node' => type == 'node', 'redfish' => false, 'error' => error.class}
    end

end

def add_credentials(credentials, allBmc)

    allBmc.peach do |s_site, d_array|
        d_array.peach do |n|
            #si ce n'est pas compatible redfish, on ne store pas
            if !n['redfish'] 
                next
            end 
            # bmc password is global for cluster nodes
            nodeName = n['node'] ? n['uid'].slice(/\w*/) : n['uid']
            begin
                n['login'], n['password'] = credentials[s_site][nodeName].split() 
            rescue NoMethodError
                n['error'] = "no password defined in console-password.yaml"

            rescue => error
                p "infra :uid #{n['uid']}, url #{n['url']} mon potentiel password : #{credentials[s_site][n['uid']]}, site #{s_site}, error : #{error.class} error  message: #{error}, nodeName : #{nodeName}"
                n['error'] = error.class
            end
        end
    end

end

def gen_json_files(allBmc, options)

    allBmc.each do |s_site, _d_array|
        dir = "#{options[:output_dir]}/platforms/production/modules/generated/files/grid5000/webfish/"+s_site

        if !Dir.exist?(dir)
            Dir.mkdir(dir)
        end
        actualFile = dir+"/webfish.json"

        File.open(actualFile, "w") do |f|  
            f.write(JSON.pretty_generate(allBmc[s_site]))   
        end
    end
    
end

##REMOVE-|
# def connect_to_redfish(url, login, password, n)

#     begin
#         chaine = "python3 lib/refrepo/redfish-client.py #{url} #{login} \"#{password}\" getinfos"
#         res = []
#         IO.popen(chaine) do |pipe|
#             res = pipe.readlines
#         end
        
#         if res.any?(/Failure/)
#             raise "Failure health or vendor, error #{res}"
#         end

#         vendor = YAML.safe_load(res[0][0..-2])
#         health = YAML.safe_load(res[1][0..-2])
#         n.store('vendor', res[0][0..-2])
#         n.store('health', res[1][0..-2])

#     rescue => error
#         #p "uid #{n['uid']}, login #{n['login']}, password #{n['password']}, error #{error.class}, message : #{error.message}"
#         n['redfish'] = false
#     end

# end

##REMOVE-|
# def loop_connect_to_redfish(allBmc)

#     allBmc.peach do |s_site, d_array|
#         d_array.peach do |n|
#             if n['redfish'] == true
#                 connect_to_redfish(n['url'], n['login'], n['password'], n)
#             end
#         end
#     end

#     #se connecter à un seul site

#     # allBmc['sophia'].peach do |n|
#     #         if n['redfish'] == true
#     #             connect_to_redfish(n['url'], n['login'], n['password'], n)
#     #         end
#     #     #p "#{n['url']}, #{n['login']} #{n['password']}"
#     # end

# end









