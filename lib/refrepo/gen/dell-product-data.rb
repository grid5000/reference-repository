require 'refrepo/input_loader'
require 'refrepo/utils'
require 'faraday'
require 'uri'
require 'json'
require 'date'


def dell_product_data
    data = get_dell_hardware
    token = get_api_token
    url = "https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/asset-entitlements"
    services_tags = data["sites"].map{ |_s_uid, s_hash| s_hash["clusters"].map{|_c_uid, c_hash| c_hash["nodes"].map{|_n_uid, n_hash| n_hash["chassis"]["serial"] }}}.flatten
    
    # We cannot retrieve service tag for roazhon11-3 #15114
    services_tags.delete("N/A")

    # API is limited to 100 services tags
    services_tags.each_slice(100).each{ |d| 
        response = Faraday.get(url, {"servicetags" => d.join(',')}) do |q|
            q.headers["Authorization"] = "Bearer #{token}"
        end
        JSON.parse(response.body).each do |product|
            begin
                set_product_data(data["sites"], product)    
            rescue
                p "#{product["serviceTag"]} has not been found"
            end
        end
    }
    
    # Manual hack for roazhon11-3 #15114
    data["sites"]["rennes"]["clusters"]["roazhon11"]["nodes"]["roazhon11-3"]["chassis"] = Hash("manufactured_at" => DateTime.new(2012,9,14).to_date,
                                                                                               "warranty_end" => DateTime.new(2017,9,14).to_date)

    outfile = File.open("input/grid5000/dell-product-data.yaml", "w")
    outfile.write(data.to_yaml)
end

def get_dell_hardware
    data = load_data_hierarchy
    data.delete_if { |key| key != 'sites' }

    data["sites"].each do |_s_uid, s_hash|
        # We treat clusters only
        s_hash.delete_if { |key| !['clusters'].include?(key) }
        # We filter on Dell cluster
        s_hash["clusters"].delete_if {|_c_uid, c_hash| !c_hash["model"].downcase.start_with?("dell")}
        s_hash["clusters"].each do |_c_uid, c_hash| 
            # We keep only nodes
            c_hash.delete_if{ |key| key != 'nodes'}
            c_hash["nodes"].each do |_n_uid, n_hash| 
                # We keep only chassis
                n_hash.delete_if{|key| key != 'chassis'}
                n_hash['chassis'].delete_if{|key| key != 'serial'}
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

def set_product_data(data, product)
    data.each do |_s, s_hash| 
        s_hash['clusters'].each do |_c, c_hash| 
            c_hash['nodes'].each do |_n, info|
                if info["chassis"]["serial"] == product["serviceTag"]
                    info["chassis"]["manufactured_at"] = DateTime.strptime(product["shipDate"], '%Y-%m-%d').to_date
                    info["chassis"]["warranty_end"] = DateTime.strptime(product["entitlements"].map{|e| e["endDate"] }.max, '%Y-%m-%d').to_date
                    info["chassis"].delete("serial")
                end
            end
        end
    end
end
