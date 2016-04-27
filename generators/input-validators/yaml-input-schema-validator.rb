#!/usr/bin/ruby

if RUBY_VERSION < "2.1"
  puts "This script requires ruby >= 2.1"
  exit
end

require 'fileutils'
require 'pathname'

dir = Pathname(__FILE__).parent

require "#{dir}/../lib/input_loader"
require "#{dir}/lib/schema_validator"

def run_validator(uid, data, schema)
  validator = HashValidator.validate(data, schema, strict = true)
  if ! validator.valid?
    errors = {uid => validator.errors}
    puts errors.to_yaml
    return false
  end
  return true
end

def yaml_input_schema_validator(global_hash)
  dir = Pathname(__FILE__).parent

  schema_global  = load_yaml_schema("#{dir}/schema-global.yaml")
  schema_site    = load_yaml_schema("#{dir}/schema-site.yaml")
  schema_cluster = load_yaml_schema("#{dir}/schema-cluster.yaml")
  schema_node    = load_yaml_schema("#{dir}/schema-node.yaml")
  
  r &= run_validator('global', global_hash, schema_global) #
  
  global_hash["sites"].each do |site_uid, site|
    
    r &= run_validator(site_uid, site, schema_site) #
    
    site["clusters"].each do |cluster_uid, cluster|
      
      r &= run_validator(cluster_uid, cluster, schema_cluster) #
      
      cluster["nodes"].each do |node_uid, node|
        
        r &= run_validator(node_uid, node, schema_node) #
        
      end
    end
  end
  return r
end

if __FILE__ == $0
  puts "Checking input data:\n\n"
  global_hash = load_yaml_file_hierarchy("#{dir}/../../input/grid5000/")
  r = yaml_input_schema_validator(global_hash)
  puts 'OK' if r
end
