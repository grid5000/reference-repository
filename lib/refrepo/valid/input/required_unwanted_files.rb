def yaml_input_required_unwanted_files(options)
  global_hash = load_yaml_file_hierarchy
  sites = options[:sites]
  clusters = options[:clusters]
  input_dir = File.expand_path('../../../../input', File.dirname(__FILE__))

  r = true

  global_hash['sites'].each do |site_uid, site|
    next if sites and !sites.include?(site_uid)

    site_input_dir = File.expand_path("grid5000/sites/#{site_uid}", input_dir)

    (Dir.entries(site_input_dir) - %w[. .. clusters networks servers pdus.yaml
                                      sensors.yaml] - ["#{site_uid}.yaml"]).each do |f|
      puts "ERROR: Unwanted file #{f} in #{site_input_dir}"
      r = false
    end

    site.fetch('clusters', {}).each do |cluster_uid, cluster|
      next if clusters and !clusters.empty? and !clusters.include?(cluster_uid)

      cluster_input_dir = File.expand_path("clusters/#{cluster_uid}", site_input_dir)

      Dir.entries(cluster_input_dir).each do |f|
        next if %w[. .. nodes pdus.yaml].include?(f)
        next if f =~ /^#{cluster_uid}(|_metrics|_pdus|_pdu|_retired|_ib|_extra|_disks).yaml(.erb)?$/

        puts "ERROR: Unwanted file #{f} in #{cluster_input_dir}"
        r = false
      end

      cluster['nodes'].each do |node_uid, node|
        # check that per-node YAML file exists for non-retired nodes
        next unless !File.exist?(File.expand_path("nodes/#{node_uid}.yaml",
                                                  cluster_input_dir)) and node['status'] != 'retired'

        puts "ERROR: Missing nodes/#{node_uid}.yaml in #{cluster_input_dir}"
        r = false
      end
    end
  end
  unless r
    puts 'Missing or unwanted files detected. This is OK if you are in the early stage of a cluster integration, but must be fixed before merging to master.'
  end
  r
end
