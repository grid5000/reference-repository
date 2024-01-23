require 'refrepo/data_loader'

def generate_puppet_clusters(options)
    if not options[:conf_dir]
        options[:conf_dir] = "#{options[:output_dir]}/platforms/production/hieradata/"
    end

    if options[:sites] != G5K_SITES
        raise "SITE options is not valid as clusters.yaml contains all sites"
    end 
    data = load_data_hierarchy
    data.delete_if { |key| key != 'sites' }
    
    yaml_data = {}
    
    data['sites'].sort.each do |s_uid, s_hash| 
        yaml_data[s_uid] = {}
        s_hash['clusters'].sort_by{|c_uid, _c_hash| [c_uid[/(\D+)/, 1], c_uid[/(\d+)/, 1].to_i]}.each do |c_uid, c_hash|
            _, f_node = c_hash["nodes"].first
            queue = f_node['supported_job_types']['queues'].sort.reverse.first
            disk_reservation = f_node['storage_devices'].filter{|d| d.key?('reservation')}.length > 0
            gpu = f_node.key?('gpu_devices') 
            if ! f_node.key?('chassis')
                puts "no chassis field for #{f_node['uid']}, setting warranty to false" 
                warrantied = false
            else
                warrantied = f_node['chassis'].key?('warranty_end') ? DateTime.parse(f_node['chassis']['warranty_end']) > DateTime.now : false
            end

            yaml_data[s_uid][c_uid] = {"queue" => queue, 
                                       "disk_reservation" => disk_reservation,
                                       "gpu" => gpu,
                                       "warrantied" => warrantied}
        end
    end

    outfile = File.open("#{options[:conf_dir]}clusters.yaml", "w")
    outfile.write({'grid5000::clusters' => yaml_data}.to_yaml)
end