require 'optparse'
require 'erb'
require 'pp'

# Process command-line options
#pp ARGV

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: bootstrap-cluster.rb [options]"

  # default
  options[:cluster_name] = "cluster"
  options[:output_dir]   = "."

  opts.on("-n", "--cluster-name [CLUSTER]", "Cluster name (ex: graoully)") do |n|
    options[:cluster_name] = n
  end

  opts.on("-o", "--output-dir [DIR]", "Output Directory (ex: input/grid5000/sites/nancy/clusters/graoully/)") do |n|
    options[:output_dir] = n
  end

  opts.on("-e", "--file-eth0 FILE", "File containing the list of mac addresses for eth0") do |n|
    options[:feth0] = n
  end

  opts.on("-b", "--file-bmc FILE", "File containing List of mac addresses for bmc") do |n|
    options[:fbmc] = n
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

raise OptionParser::MissingArgument,"Missing --file-eth0 (-e) command line argument" if options[:feth0].nil?
raise OptionParser::MissingArgument,"Missing --file-bmc (-b) command line argument" if options[:fbmc].nil?

#pp options

# Output file
output_file = File.join(options[:output_dir], options[:cluster_name] + '.yaml')
dirname = File.dirname(output_file)
FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

#puts "Output file: #{output_file}"
eth0_list = File.readlines(options[:feth0]).map { |n| n.strip }
bmc_list  = File.readlines(options[:fbmc] ).map { |n| n.strip }

# Add ":" separator in mac addresses
eth0_list = eth0_list.map{|mac| mac.split(%r{(..)}).reject(&:empty?).join(":") }
bmc_list  =  bmc_list.map{|mac| mac.split(%r{(..)}).reject(&:empty?).join(":") }

cluster_name = options[:cluster_name]

erb = ERB.new(File.read("templates/cluster.yaml.erb"))

File.open(output_file, "w+") { |f|
  f.write(erb.result(binding))
}
