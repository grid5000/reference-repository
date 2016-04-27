#!/usr/bin/ruby

if RUBY_VERSION < "2.1"
  puts "This script requires ruby >= 2.1"
  exit
end

require 'pp'
require '../lib/input_loader'

# replace default deep_merge before calling load_yaml_file_hierarchy
class ::Hash
  def deep_merge(other_hash)
    # merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    
    merger = proc { |key, v1, v2| 
      if Hash === v1 && Hash === v2 
        v1.merge(v2, &merger) 
      else
        v1.gsub!('!duplicated: ') if String === v1
        v2.gsub!('!duplicated: ') if String === v2
        if Hash === v1 || Hash === v2
          # for example, this occurs if there are some empty entries on yaml files that need to be deleted (ex: parasilo-1 => {})
          # return a hash because it is needed by expand_square_brackets
          { 'v1' => v1, 'v2' => v2, 'error' => "!duplicated: #{key}" }
        else
          # remove the following 'if' if you want all the duplicated keys
          #if v1 != v2
            "!duplicated: '#{v1}' '#{v2}'"
          #else
          #  v2
          #end
        end
      end
    }
    
    self.merge(other_hash, &merger)
  end
end

global_hash = load_yaml_file_hierarchy("../../input/grid5000/")

# remove entries that are not duplicate
global_hash.deep_reject! { |k, v| !(
                                    (v.is_a?(Hash) && !v.empty?) || 
                                    v.is_a?(String) && v.start_with?('!duplicated:')
                                    ) }

# remove ip, mac and mounted properties (as it can be use to bootstrap the installation of a cluster)
global_hash.deep_reject! { |k, v| k == 'ip' || k == 'mac' || k == 'mounted' }
global_hash.deep_reject! { |k, v| v == {} }

if global_hash.empty?
  puts "OK: no duplicate entries."
else
  puts global_hash.to_yaml
end


