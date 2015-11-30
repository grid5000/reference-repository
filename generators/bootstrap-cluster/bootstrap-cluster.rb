require 'erb'
require 'pp'

erb = ERB.new(File.read("input/graoully.yaml.erb"))

puts erb.result(binding)
