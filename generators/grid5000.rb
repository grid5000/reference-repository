require 'pp'
require 'rubygems'
require 'fileutils'
require 'json'
require 'time'
require File.dirname(__FILE__)+'/lib/core_extensions'
require File.dirname(__FILE__)+'/lib/g5k_generator'

usage = %{ 
  A tool to generate the Grid5000 reference data.
  
  Usage:
    ruby grid5000.rb [input files] [options]
  Options:
    -s : simulation mode
    
}
# true if we want to simulate, else false.
simulation_mode = !$*.delete("-s").nil?
if $*.empty?
  puts usage
elsif ($*.map{|file| File.exists?(file) && File.extname(file) == ".rb"}.include? false)
  puts "Error: your input files do not exist or are not ruby files (.rb extension)."
else
  description_files = $*
  puts "[Input files:\t\t #{description_files.join(", ")}]"
  puts "[Simulation mode:\t #{simulation_mode}]"
  generator = G5K::ReferenceGenerator.new({:uid => "grid5000", :type => "grid"}, *description_files)
  data = generator.generate
  generator.write(File.expand_path(File.dirname(__FILE__), "../data"), :simulate => simulation_mode)
end