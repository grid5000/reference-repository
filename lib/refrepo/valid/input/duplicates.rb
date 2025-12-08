# replace default deep_merge before calling load_yaml_file_hierarchy
class ::Hash
  def deep_merge(other_hash)
    # merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }

    merger = proc { |key, v1, v2|
      if v1.is_a?(Hash) && v2.is_a?(Hash)
        v1.merge(v2, &merger)
      else
        v1.gsub!('!duplicated: ') if v1.is_a?(String)
        v2.gsub!('!duplicated: ') if v2.is_a?(String)
        v1 = '!duplicated: false' if v1.is_a?(FalseClass)
        v1 = '!duplicated: true' if v1.is_a?(TrueClass)
        v2 = '!duplicated: false' if v2.is_a?(FalseClass)
        v2 = '!duplicated: true' if v2.is_a?(TrueClass)
        v1 = '!duplicated: nil' if v1.is_a?(NilClass)
        v2 = '!duplicated: nil' if v2.is_a?(NilClass)
        if v1.is_a?(Hash) || v2.is_a?(Hash)
          # for example, this occurs if there are some empty entries on yaml files that need to be deleted (ex: parasilo-1 => {})
          # return a hash because it is needed by expand_square_brackets
          { 'v1' => v1, 'v2' => v2, 'error' => "!duplicated: #{key}" }
        else
          # remove the following 'if' if you want all the duplicated keys
          # if v1 != v2
          "!duplicated: '#{v1}' '#{v2}'"
          # else
          #  v2
          # end
        end
      end
    }

    merge(other_hash, &merger)
  end
end

def yaml_input_find_duplicates(options)
  refapi_hash = load_yaml_file_hierarchy

  refapi_hash['sites'].sort.each do |site_uid, site|
    refapi_hash['sites'].delete(site_uid) if options.key?(:sites) && !options[:sites].include?(site_uid)

    site.fetch('clusters', {}).sort.each do |cluster_uid, cluster|
      if options.key?(:clusters) && !options[:clusters].empty? && !options[:clusters].include?(cluster_uid)
        site['clusters'].delete(cluster_uid)
      end
      cluster['nodes'].sort.each do |node_uid, node|
        cluster['nodes'].delete(node_uid) if node.key?('status') && node['status'] == 'retired'
      end
    end
  end

  # remove entries that are not duplicate
  refapi_hash.deep_reject! do |_k, v|
    !(
  (v.is_a?(Hash) && !v.empty?) ||
      v.is_a?(String) && v.start_with?('!duplicated:')
)
  end

  # remove ip, mac and mounted properties (as it can be use to bootstrap the installation of a cluster)
  #  refapi_hash.deep_reject! {|k, v| k == 'ip' || k == 'mac' || k == 'mounted'}
  refapi_hash.deep_reject! { |_k, v| v == {} }

  if refapi_hash.empty?
    puts 'OK: no duplicate entries.'
    true
  else
    puts refapi_hash.to_yaml
    false
  end
end
