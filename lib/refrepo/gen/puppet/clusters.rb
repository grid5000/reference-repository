require 'refrepo/data_loader'

def generate_puppet_clusters(options)
    
    if not options[:conf_dir]
        options[:conf_dir] = "#{options[:output_dir]}/platforms/production/hieradata/"
    end
    # Loading current data from hiera
    hiera = YAML.load_file("#{options[:conf_dir]}clusters.yaml")['grid5000::clusters']
    
    # Updating data from refrepo
    refrepo = load_data_hierarchy
    refrepo.delete_if { |key| key != 'sites' }
    
    refrepo['sites'].select{ |k, _v| options[:sites].include? k}.sort.each do |s_uid, s_hash| 
        if ! hiera.key? s_uid
            puts "Add #{s_uid}"
            hiera[s_uid] = {}
        end
        s_hash['clusters'].sort_by{|c_uid, _c_hash| [c_uid[/(\D+)/, 1], c_uid[/(\d+)/, 1].to_i]}.each do |c_uid, c_hash|
            if ! hiera[s_uid].key? c_uid
                puts "  Add #{s_uid}"
                hiera[s_uid][c_uid] = {}
            end
            _, f_node = c_hash["nodes"].first
            queue = f_node['supported_job_types']['queues'].select{|q| q != 'admin'}[0]
            disk_reservation = f_node['storage_devices'].filter{|d| d.key?('reservation')}.length > 0
            gpu = f_node.key?('gpu_devices')
            if ! f_node.key?('chassis')
                puts "no chassis field for #{f_node['uid']}, has g5k-checks data been imported ?" 
                warrantied = false
            else
                warrantied = f_node['chassis'].key?('warranty_end') ? DateTime.parse(f_node['chassis']['warranty_end']) > DateTime.now : false
            end
            c_data = {"queue" => queue, 
                "disk_reservation" => disk_reservation,
                "gpu" => gpu,
                "warrantied" => warrantied}
            if hiera[s_uid][c_uid] != c_data
                diff = hiera[s_uid][c_uid].dup.delete_if { |k, v| c_data[k] == v }.merge!(c_data.dup.delete_if { |k, _v| hiera[s_uid][c_uid].has_key?(k) })
                puts "#{s_uid}-#{c_uid}  Changes detected #{diff}"
                hiera[s_uid][c_uid] = c_data
            end
        end
    end

    outfile = File.open("#{options[:conf_dir]}clusters.yaml", "w")
    outfile.write({'grid5000::clusters' => hiera}.to_yaml)
end