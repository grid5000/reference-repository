# Load a hierarchy of YAML file into a Ruby hash

require 'yaml'
require '../lib/hash/hash.rb'

def load_yaml_file_hierarchy(directory)

  global_hash = {} # the global data structure
  
  Dir.chdir(directory) {
  
    # Recursively list the .yaml files.
    # The order in which the results are returned depends on the system (http://ruby-doc.org/core-2.2.3/Dir.html).
    # => List deepest files first as they have lowest priority when hash keys are duplicated.
    list_of_yaml_files = Dir['**/*.y*ml'].sort_by { |x| -x.count('/') }
    
    list_of_yaml_files.each { |filename|
      
      # Load YAML
      file_hash = YAML::load_file(filename)
      if not file_hash 
        puts "Error loading '#{filename}'"
        next
      end
      
      # Inject the file content into the global_hash, at the right place
      path_hierarchy = File.dirname(filename).split('/')     # Split the file path (path relative to input/)
      file_hash = Hash.from_array(path_hierarchy, file_hash) # Build the nested hash hierarchy according to the file path
      global_hash = global_hash.deep_merge(file_hash)        # Merge global_hash and file_hash. The value for entries with duplicate keys will be that of file_hash

      # Expand the hash. Done at each iteration for enforcing priorities between duplicate entries:
      # ie. keys to be expanded have lowest priority on existing entries but higher priority on the entries found in the next files
      global_hash.expand_angle_brackets()

    }

  }

  return global_hash

end
