#!/usr/bin/ruby

require 'pp'
require 'fileutils'
require 'pathname'

require '../lib/input_loader'
require './lib/schema_validator'

schema_global  = load_yaml_schema('schema-global.yaml')
schema_site    = load_yaml_schema('schema-site.yaml')
schema_cluster = load_yaml_schema('schema-cluster.yaml')
schema_node    = load_yaml_schema('schema-node.yaml')

def run_validator(uid, data, schema)
  validator = HashValidator.validate(data, schema, strict = true)
  if ! validator.valid?
    errors = {uid => validator.errors}
    puts errors.to_yaml
  end
end

global_hash = load_yaml_file_hierarchy("../../input/grid5000/")

run_validator('global', global_hash, schema_global) #

global_hash["sites"].each do |site_uid, site|

  run_validator(site_uid, site, schema_site) #

  site["clusters"].each do |cluster_uid, cluster|

    run_validator(cluster_uid, cluster, schema_cluster) #

    cluster["nodes"].each do |node_uid, node|

      run_validator(node_uid, node, schema_node) #

    end
  end
end
