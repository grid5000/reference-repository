# frozen_string_literal: true

require 'refrepo/data_loader'

def generate_puppet_clusters(options)
  clusters_filepath = "#{options[:output_dir]}/platforms/production/hieradata/clusters.yaml".freeze
  # Loading current data from hiera
  hiera = YAML.load_file(clusters_filepath)['grid5000::clusters']

  # Updating data from refrepo
  refrepo = load_data_hierarchy
  refrepo.delete_if { |key| key != 'sites' }

  refrepo['sites'].select { |k, _v| options[:sites].include? k }.sort.each do |s_uid, s_hash|
    unless hiera.key? s_uid
      puts "Add #{s_uid}"
      hiera[s_uid] = {}
    end
    s_hash['clusters'].sort_by { |c_uid, _c_hash| split_cluster_node(c_uid) }.each do |c_uid, c_hash|
      unless hiera[s_uid].key? c_uid
        puts "  Add #{s_uid}"
        hiera[s_uid][c_uid] = {}
      end
      _, f_node = c_hash['nodes'].first
      queues = f_node['supported_job_types']['queues'].reject { |q| q == 'admin' }
      queue = if queues.include?('abaca') && queues.include?('default')
                raise "abaca and default queue are exclusive for #{c_uid}"
              elsif queues.include?('abaca')
                'production'
              elsif queues.size == 1
                queues.first
              else
                raise "Cannot find queue for #{c_uid}. Queues: #{queues.inspect}"
              end
      disk_reservation = f_node['storage_devices'].filter { |d| d.key?('reservation') }.length > 0
      gpu = f_node.key?('gpu_devices')
      keep_alive_nodes_count = c_hash['keep_alive_nodes_count']
      if !f_node.key?('chassis')
        puts "no chassis field for #{f_node['uid']}, has g5k-checks data been imported ?"
        warrantied = false
      else
        warrantied = f_node['chassis'].key?('warranty_end') ? DateTime.parse(f_node['chassis']['warranty_end']) > DateTime.now : false
      end
      c_data = { 'queue' => queue,
                 'disk_reservation' => disk_reservation,
                 'gpu' => gpu,
                 'keep_alive_nodes_count' => keep_alive_nodes_count,
                 'warrantied' => warrantied }
      next unless hiera[s_uid][c_uid] != c_data

      diff = hiera[s_uid][c_uid].dup.delete_if { |k, v| c_data[k] == v }.merge!(c_data.dup.delete_if do |k, _v|
                                                                                  hiera[s_uid][c_uid].has_key?(k)
                                                                                end)
      puts "#{s_uid}-#{c_uid}  Changes detected #{diff}"
      hiera[s_uid][c_uid] = c_data
    end
  end

  outfile = File.open(clusters_filepath, 'w')
  outfile.write({ 'grid5000::clusters' => hiera }.to_yaml)
end
