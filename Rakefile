require 'fileutils'
require 'json'
require 'logger'

ROOT_DIR = File.expand_path File.dirname(__FILE__)
LIB_DIR = File.join(ROOT_DIR, "generators", "lib")
$LOAD_PATH.unshift(LIB_DIR) unless $LOAD_PATH.include?(LIB_DIR)

require 'grid5000'

task :environment do
  Dir.chdir(ROOT_DIR)
  @logger = Logger.new(STDERR)
  @logger.level = Logger.const_get((ENV['DEBUG'] || 'INFO').upcase)
end

namespace :g5k do
  desc "Generates the JSON files based on the generators, for all sites.\nUse SITE=<SITE-NAME> if you wish to restrict the generation to a specific site.\nUse DRY=1 to simulate the execution."
  task :generate => :environment do
    site = if ENV['SITE']
      ENV['SITE']
    else
      "*"
    end
    command = "#{File.join(ROOT_DIR, "generators", "grid5000")} #{File.join(ROOT_DIR, "generators", "input", "#{site}.rb")} #{File.join(ROOT_DIR, "generators", "input", "#{site}.yaml")}"
    command << " -s" if ENV['DRY'] && ENV['DRY'] != "0"
    @logger.info "Executing #{command.inspect}..."
    system command
  end
end

# TESTS
# Deletion: 
#   rake -s oar:generate FROM=4cfebf92e9cce05315782b51e05eded4ab4f0e7e TO=7d2648eaad7dbbc6f1fdb9c0279f73d374ccd47a
#
# Update: 
# rake -s oar:generate FROM=7d2648eaad7dbbc6f1fdb9c0279f73d374ccd47a TO=bb528643003757942521942eaeab74b15aaa976d
#
# Add: 
#   rake -s oar:generate FROM=be9f7338b9750ce675447c13d172157992041ec1 TO=7dc3a4101a657230b7ad0534025a7ca93c905411
#
# All: 
#   rake -s oar:generate FROM=be9f7338b9750ce675447c13d172157992041ec1 TO=7d2648eaad7dbbc6f1fdb9c0279f73d374ccd47a
# 
namespace :oar do
  desc "Generates the oaradmin lines to update the OAR database after a change in the reference repository.\nUse FROM=<SHA-ID> and TO=<SHA-ID> to specify the starting and ending commits.\nUse -s to suppress the 'in directory' announcement."
  task :generate => :environment do
    if ENV['FROM'].nil? || ENV['FROM'].empty?
      @logger.fatal "You MUST specify a commit id from where to start using the FROM=<SHA-ID> argument. Ex: rake -s oar:generate FROM=be9f7338b9750ce675447c13d172157992041ec1 TO=7dc3a4101a657230b7ad0534025a7ca93c905411 2> /dev/null" 
      exit(1)
    end
    ENV['TO'] ||= 'HEAD'
    @logger.info "Analysing changes between #{ENV['FROM']}..#{ENV['TO']}..."
    
    commands = []
    diff = `git diff --name-status #{ENV['FROM']}..#{ENV['TO']}`
    
    diff.split("\n").each do |line|
      action, filename = line.split("\t")
      next unless filename =~ %r{.+/nodes/.+}
      
      node_uid, site_uid, grid_uid = filename.gsub(/\.json/,'').split("/").values_at(-1, -5, -7)
      cluster_uid = node_uid.split("-")[0]
      host = [node_uid, site_uid, grid_uid, "fr"].flatten.join(".")
      
      if ENV['SITE'] && !ENV['SITE'].split(",").include?(site_uid)
        @logger.info "Skipping #{host} since you only want changes that occured on #{ENV['SITE'].inspect}"
        next
      end
      
      command = "oaradmin resources"
      
      case action
      when "A", "C", "M"
        node_properties = JSON.parse(File.read(filename))
        cluster_properties = JSON.parse(File.read(filename.gsub(%r{/nodes.*}, "/#{cluster_uid}.json")))
        cluster = Grid5000::Cluster.new(cluster_properties)
        node = Grid5000::Node.new(cluster, node_properties)
        begin
          export = node.export("oar-2.4")
        rescue Grid5000::MissingProperty => e
          @logger.warn "Error when exporting #{host}: #{e.message}. Skipped."
          next
        end
        if action == "M"  # modification of a file
          command.concat(" -s node=#{host} ")
        else              # new file
          command.concat(" -a node=#{host}/cpu={#{node.properties['architecture']['smp_size']}}/core={#{export['cpucore']}} ")
        end
        command.concat(" -p ").concat( export.to_a.map{|(k,v)|
          if v.nil?
            nil
          elsif v.kind_of?(String) && v =~ / / # to remove after oaradmin correctly parses options
            [k, v.inspect.inspect].join("=")
          else
            [k, v.inspect].join("=")
          end
        }.compact.join(" -p ") )          
      when "D"            # deletion of a file
        command.concat(" -d node=#{host}")
      else 
        @logger.warn "Don't know what to do with #{line.inspect}. Ignoring."
        next
      end
      commands << command
    end
    commands.each do |command|
      puts command
    end
  end
end
