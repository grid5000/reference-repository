require 'pp'
require 'rubygems'
require 'fileutils'
require 'json/pure'
require 'yaml'
require 'time'
require File.dirname(__FILE__)+'/lib/core_extensions'
require File.dirname(__FILE__)+'/lib/g5k_generator'

usage = %{ 
  A tool to generate the Grid5000 reference data.
  
  Usage:
    ruby grid5000.rb [input files] [config files] [options]
  Options:
    -s : simulation mode
  Notes:
    input files must be RUBY files and end with a .rb extension.
    config files mst be YAML files and end with a .yaml extension.
}

# true if we want to simulate:
simulation_mode = !$*.delete("-s").nil?

if $*.empty?
  puts usage
  exit 1
elsif ($*.map{|file| File.exists?(file)}.include? false)
  puts "Error: one of your input file do not exist."
  exit 2
else
  description_files = $*
  input = {}
  config = {}
  description_files.each do |filename|
    case File.extname(filename)
    when ".rb"    then input[File.basename(filename, ".rb")] = File.read(filename)
    when ".yaml"  then config[File.basename(filename, ".yaml")] = YAML.load_file(filename)
    end
  end
  puts "[Input files:\t\t #{input.keys.join(", ")}]"
  puts "[Config files:\t\t #{config.keys.join(", ")}]"
  puts "[Simulation mode:\t #{simulation_mode}]"
  generator = G5K::ReferenceGenerator.new({:uid => "grid5000", :type => "grid"}, :input => input, :config => config)
  data = generator.generate
  directory_to_write = File.expand_path File.join(File.dirname(__FILE__), "../data")
  generator.write(directory_to_write, :simulate => simulation_mode)
  exit 0
end
