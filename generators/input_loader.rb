#!/usr/bin/ruby

require 'pp'
require 'pathname'
require 'yaml'
require 'json'

# Merge a and b. If a and b are hashes, they are recursively merged.
# - a and b might be strings or nil. 
# - b values have the highest priority (if not nil).
def deep_merge_entries(a, b)
  if b.is_a?(Hash)
    a.is_a?(Hash) ? a.deep_merge(b) : b
  else
    b.nil? ? a : b
  end
end

# Extend Hash with helper methods needed to convert input data files to ruby Hash
class ::Hash

  # Recursively merge this Hash with another (ie. merge nested hash)
  # Returns a new hash containing the contents of other_hash and the contents of hash. The value for entries with duplicate keys will be that of other_hash:
  # a = {"key": "value_a"}
  # b = {"key": "value_b"}
  # pp a.deep_merge(b) => {:key=>"value_b"}
  # pp b.deep_merge(a) => {:key=>"value_a"}
  def deep_merge(other_hash)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    self.merge(other_hash, &merger)
  end

  # Merge keys that match "PREFIX-<a-b>" with others keys that begins by "PREFIX-" 
  # and that ends with x, where a<=x<=b.
  # - This is done recursively (for this Hash and every Hashes it may contain).
  # - PREFIX-<a-b> values have lower priority on existing PREFIX-x keys.
  # - "a" and/or "b" may be omited (ie. "PREFIX-<a->", "PREFIX-<-b>" or "PREFIX-<->"), meaning that there are no lower and/or upper bound for x.
  #   * If only a is omited, a == 1.
  #   * If b is omited, only existing keys are modified (no keys are created). Otherwise, PREFIX-<a> to PREFIX-<b> entries are created (if missing).
  # Example:
  # {"foo-1": {a: 0}, "foo-2": {a: 0}, "foo-3": {a: 0}, "foo-<2->": {b: 1}}.expand_angle_brackets()
  #  -> {"foo-1": {a: 0}, "foo-2": {a: 0, b:1},  "foo-3": {a: 0, b: 0}}
  def expand_angle_brackets()
    dup = self.clone # because can't add a new key into hash during iteration

    # Looking up for PREFIX-<a-b> keys
    dup.each { |key_ab, value_ab|
      prefix, a, b = key_ab.to_s.scan(/^(.*)-<(\d*)-(\d*)>$/).first
      next if not a and not b # not found
      a != "" ? a = a.to_i : a = 1
      b != "" ? b = b.to_i : b

      if b != ""

        # Merge keys, creating missing entries if needed.
        (a..b).each { |x|
          key = "#{prefix}-#{x}"
          key = key.to_sym if key_ab.is_a?(Symbol)

          # For duplicate entries, the value of PREFIX-x is kept.
          self[key] = deep_merge_entries(value_ab, self[key])
        }

      else
        # Modify only existing keys. Looking up for PREFIX-x keys.
        dup.each { |key_x, value_x|
          next if key_x.class != key_ab.class
          x = key_x.to_s.scan(/^#{prefix}-(\d*)$/).first
          x = x.first if x
          next if not x or x.to_i < a

          # For duplicate entries, the value of PREFIX-x is kept.
          self[key_x] = deep_merge_entries(value_ab, value_x)
        }
      end
          
      # Delete entry "PREFIX-<a-b>"
      self.delete(key_ab)
    }

    # Do it recursivly
    self.each { |key, value|
      if value.is_a?(Hash)
        value.expand_angle_brackets()
      end
    }
  end

  # Add an element composed of nested Hashes made from elements found in "array" argument
  # i.e.: from_array([a, b, c],"foo") -> {a: {b: {c: "foo"}}}
  def self.from_array(array, value)
    return array.reverse.inject(value) { |a, n| { n => a } }
  end
end

global_hash = {} # the global data structure

Dir.chdir("../input/grid5000/")

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
  
  # Expand the hash
  file_hash.expand_angle_brackets()
 
  # Inject the file content into the global_hash, at the right place
  path_hierarchy = File.dirname(filename).split('/')     # Split the file path (path relative to input/)
  file_hash = Hash.from_array(path_hierarchy, file_hash) # Build the nested hash hierarchy according to the file path
  global_hash = global_hash.deep_merge(file_hash)        # Merge global_hash and file_hash. The value for entries with duplicate keys will be that of file_hash
}

#pp global_hash

#pp data
#puts JSON.generate(data)



