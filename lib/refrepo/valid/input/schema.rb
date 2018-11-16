#!/usr/bin/ruby

require 'fileutils'
require 'pathname'

require 'refrepo/input_loader'

require_relative "./lib/schema_validator"

def run_validator(uid, data, schema)
  validator = HashValidator.validate(data, schema, strict = true)
  if ! validator.valid?
    errors = {uid => validator.errors}
    puts errors.to_yaml
    return false
  end
  return true
end

def yaml_input_schema_validator(options)
  global_hash = load_yaml_file_hierarchy
  sites = options[:sites]
  clusters = options[:clusters]
  schema_global  = load_yaml_schema(File.expand_path("./schemas/schema-global.yaml", File.dirname(__FILE__)))
  schema_site    = load_yaml_schema(File.expand_path("./schemas/schema-site.yaml", File.dirname(__FILE__)))
  schema_cluster = load_yaml_schema(File.expand_path("./schemas/schema-cluster.yaml", File.dirname(__FILE__)))
  schema_node    = load_yaml_schema(File.expand_path("./schemas/schema-node.yaml", File.dirname(__FILE__)))
  schema_network_equipments = load_yaml_schema(File.expand_path("./schemas/schema-network_equipments.yaml", File.dirname(__FILE__)))

  r = true

  r &= run_validator('global', global_hash, schema_global) #

  global_hash["sites"].each do |site_uid, site|
    next if sites and not sites.include?(site_uid)

    r &= run_validator(site_uid, site, schema_site) #

    site['networks'].each do |network_equipment_uid, network_equipment|
      r &= run_validator(site_uid, network_equipment, schema_network_equipments)
    end

    site["clusters"].each do |cluster_uid, cluster|
      next if clusters and not clusters.empty? and not clusters.include?(cluster_uid)      
      
      r &= run_validator(cluster_uid, cluster, schema_cluster) #

      cluster["nodes"].each do |node_uid, node|
        next if node == nil || node["status"] == "retired"

        r &= run_validator(node_uid, node, schema_node) #
      end
    end
  end
  return r
end
