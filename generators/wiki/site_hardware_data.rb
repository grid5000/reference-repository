# coding: utf-8
require 'pp'
require_relative 'site_hardware.rb'

global_hash = load_yaml_file_hierarchy(File.expand_path("../../input/grid5000/", File.dirname(__FILE__)))

sites = global_hash['sites'].keys.sort

pp get_hardware(sites)
