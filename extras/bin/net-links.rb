#!/usr/bin/env ruby

ROOT_DIR = File.expand_path('../..', __FILE__)
LIB_DIR = File.join(ROOT_DIR, "lib")
$LOAD_PATH.unshift LIB_DIR unless $LOAD_PATH.include?(LIB_DIR)

require 'net-links-engine'

netlinks = NetLinksEngine.new
netlinks.parse!(ARGV)
netlinks.run!
