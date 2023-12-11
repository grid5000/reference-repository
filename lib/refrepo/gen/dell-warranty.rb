require 'refrepo/input_loader'
require 'refrepo/utils'
require 'faraday'
require 'uri'
require 'json'


def dell_warranty_check
    data = get_dell_hardware
    token = get_api_token
    url = "https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/asset-entitlements"
    services_tags = data.map{ |_s_uid, d| d["servers"].merge(d["nodes"]).map{|_k, v1| v1["serial"]}}.flatten
    # API is limited to 100 services tags
    services_tags.each_slice(100).each{ |d| 
        response = Faraday.get(url, {"servicetags" => d.join(',')}) do |q|
            q.headers["Authorization"] = "Bearer #{token}"
        end
        JSON.parse(response.body).each do |r|
            begin
                service_tag = r["serviceTag"]
                ship_date = Time.parse(r["shipDate"]).strftime('%Y-%m-%d')
                warranty_date = Time.parse(r["entitlements"].map{|e| e["endDate"] }.max).strftime('%Y-%m-%d')
                start = Time.now
                set_dates(data, service_tag, ship_date, warranty_date)
                finish = Time.now
                seconds = sprintf("%0.02f", (finish - start) % 60)
                p "#{service_tag}: #{ship_date} -> #{warranty_date} (#{seconds})"
            rescue
                p "No asset found, #{r["serviceTag"]} is probably not a Dell hardware"
            end
        end
    }
    return data
end

def get_dell_hardware
    input = load_data_hierarchy
    data = Hash.new()
    input["sites"].each do |s_uid, s_data|
        data[s_uid] = {"servers" => Hash.new(), "nodes" => Hash.new()}
        # Retrieving Dell servers, based on the 7 characters length of service tag, as it isn't stated
        s_data["servers"].select{|_k, v| v.key?("serial") && !v["serial"].nil? && v["serial"].length == 7}.each do |uid, v|
        data[s_uid]["servers"][uid] = Hash("serial" => v["serial"])
        end
        # Retrieving Dell nodes, with a blacklist of sirius and estats due to a bad format
        s_data["clusters"].select{|c, _v| c != 'sirius' && c != 'estats'}.each do |_c_uid, c_data|
            c_data["nodes"].select{|_n, v| v["chassis"]["serial"].length == 7 && v["chassis"]["manufacturer"] == "Dell Inc." }.each do |n_uid, n_data|
                data[s_uid]["nodes"][n_uid] = Hash("serial" => n_data["chassis"]["serial"])
            end
        end

    end

    return data
end

def get_api_token
    url = 'https://apigtwb2c.us.dell.com/auth/oauth/v2/token'
    conf = RefRepo::Utils.get_api_config
    if !conf.key?('dell_api')
        raise "You must add the dell_api configuration in ~/.grid5000_api.yml"
    end
    api_cred = /(.*)\((.*)\)/.match(conf['dell_api'])  

    params = {
        client_id: api_cred[1],
        client_secret: api_cred[2],
        grant_type: "client_credentials"
    }   

    response = Faraday.post(url) do |q|
        q.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        q.body = URI.encode_www_form(params)
    end

    return JSON.parse(response.body)["access_token"] 
end

def set_dates(data, service_tag, ship_date, warranty_date)
    data.each do |site, type| 
        type.each do |e, nodes| 
            nodes.each do |uid, info|
                if info["serial"] == service_tag 
                    data[site][e][uid]["ship_date"] = ship_date
                    data[site][e][uid]["warranty_date"] = warranty_date
                end
            end
        end
    end
end

