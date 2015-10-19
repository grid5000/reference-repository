#!/usr/bin/ruby

require 'pathname'
require 'yaml'
require 'json'

# Extend Hash with helper methods needed to convert input data files to ruby Hash
class ::Hash

  # Recursively merge this Hash with another
  def deep_merge(second)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    self.merge(second, &merger)
  end

  # Merge keys that match "PREFIX-<a-b>" with others keys that begins by
  #   "PREFIX-" and that ends with x, where a<=x<=b
  # a and/or b may be ommited, meaning that there are no lower and/or upper bound for x
  # This is done recursively (for this Hash and every Hashes it contains)
  #  i.e.:
  # {"foo-1": {a: 0}, "foo-2": {a: 0}, "foo-3": {a: 0}, "foo-<2->": {b: 1}}.kbracket_merge()
  #  -> {"foo-2": {a: 0, b:1},  "foo-3": {a: 0, b: 0}}
  # TODO: only "<->" suffix is currently implemented
  def kbracket_merge()
    self.each { |k_all, v_all|
      if k_all.to_s.end_with?('-<->') and v_all.is_a?(Hash)
        key_prefix_to_merge = k_all.to_s.sub(/-<->$/,'')
        self.each { |k, v|
          if k.to_s.start_with?(key_prefix_to_merge)
            self[k] = v_all.deep_merge(v)
          end
        }
        self.delete(k_all)
      end
    }
    self.each { |k, v|
      if v.is_a?(Hash)
        v.kbracket_merge()
      end
    }
  end

  # Add an element composed of nested Hashes made from elements found in "array" argument
  # i.e.: from_array([a, b, c],"foo") -> {a: {b: {c: "foo"}}}
  def self.from_array(array, value)
    return array.reverse.inject(value) { |a, n| { n => a } }
  end
end

#TODO: Ensure that deepest elements in input files hierarchy have lowest priority
data = Hash.new

Dir.chdir("input")
Dir['**/*.y*ml'].each { |f|
   node_path = Pathname.new(f)
   node_dir, _ = node_path.split()

   node_hierarchy = node_dir.to_s.split('/')
   node_value = YAML::load_file(node_path)

   node_data = Hash.from_array(node_hierarchy,node_value)
   data = data.deep_merge(node_data)
}
data.kbracket_merge()

puts JSON.generate(data)

