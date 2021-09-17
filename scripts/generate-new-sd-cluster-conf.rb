#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../lib')))
require 'fileutils'
require 'yaml'
require 'refrepo'

data = load_data_hierarchy

sites = data['sites'].map { |site_uid, _ | site_uid }

sites.each do |s|
  data['sites'][s]['clusters'].each do |cluster_uid, cluster|
    puts "Cluster #{cluster_uid} at #{s}"
    new_sd_conf = {}
    cluster['nodes'].first[1]['storage_devices'].each do |sd|
      new_sd_conf['storage_devices'] ||= {}
      new_sd_conf['storage_devices'][sd['by_path'].split('/').last] = {}
      new_sd_conf['storage_devices'][sd['by_path'].split('/').last]['interface'] = sd['interface']
      new_sd_conf['storage_devices'][sd['by_path'].split('/').last]['id'] = sd['id']
      new_sd_conf['storage_devices'][sd['by_path'].split('/').last]['reservation'] = sd['reservation'] if sd['reservation']
    end
    puts new_sd_conf.to_yaml
    puts
  end
end
