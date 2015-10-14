#
require 'fileutils'
require 'json'
require 'logger'
require 'restfully'

ROOT_DIR = File.expand_path File.dirname(__FILE__)
LIB_DIR = File.join(ROOT_DIR, "generators", "lib")
$LOAD_PATH.unshift(LIB_DIR) unless $LOAD_PATH.include?(LIB_DIR)

require 'grid5000'

task :environment do
  Dir.chdir(ROOT_DIR)
  @logger = Logger.new(STDERR)
  @logger.level = Logger.const_get((ENV['DEBUG'] || 'INFO').upcase)
end

task :api_sites  do
  api_logger = Logger.new("/dev/null")
  api_logger.level = Logger::FATAL
  @api = Restfully::Session.new(:configuration_file => File.expand_path("~/.restfully/api.grid5000.fr.yml"),:logger => api_logger,:base_uri => 'https://api.grid5000.fr/sid')
  @api_sites = if ENV['SITE']
    [@api.root.sites[ENV['SITE'].to_sym]]
  else
    @api.root.sites
  end
end

task :hosts do
  # HOSTS=gw.lille
  # HOSTS=*.lille
  # SITES=lille => HOSTS=*.lille
  # SITES=* => HOSTS=*.*
  site = ENV['SITE']
  host = ENV['HOST']
  if site != nil
    host = "*.#{site}"
  elsif host != nil
    abort "HOST must be on the form <hostname>.<site>. You provided '#{host}'." if host.scan(/^(\S+)\.(\S+)$/).empty?
  else
    abort "You must provide SITE= , (SITE=lille, or SITE=*), or a HOST, (HOST=gw.lille, or HOST=*.lille, or HOST=sw-*.lille)"
  end
  abort "You must provide HOST= , (HOST=gw.lille, or HOST=*.lille, or HOST=sw-*.lille)" if host.nil?
  @host = host
end


namespace :g5k do
  desc "Generates the JSON files based on the generators, for all sites.\nUse SITE=<SITE-NAME> if you wish to restrict the generation to a specific site.\nUse DRY=yes to simulate the execution."
  task :generate => [:environment,:hosts] do
    host,site = @host.scan(/(\S+)\.(\S+)/).flatten
    root_dir_input = "#{ROOT_DIR}/generators/input/sites"
    command = File.join(ROOT_DIR, "generators", "grid5000")
    command += " " + File.join(root_dir_input, site,"#{site}.rb")
    command += " " + File.join(root_dir_input, site,"clusters", "*", "#{host}.rb")
    command += " " + File.join(root_dir_input, site,"clusters", "*", "nodes", "#{host}*.yaml")
    command += " " + File.join(root_dir_input, site,"clusters", "*", "#{host}_manual.yaml")
    command += " " + File.join(root_dir_input, site,"pdus.rb")

    command << " -s" if ENV['DRY'] == "yes"
#    puts command
    sh command
  end
end

# rake deadnodes:reasons
# rake deadnodes:tofix
namespace :deadnodes do

  desc "List all dead nodes and the reason why they are dead. (SITE=)"
  task :reasons => [:environment,:api_sites] do
    @logger.level = Logger::INFO
    @reasons = true
    Rake::Task["deadnodes:browse"].execute
  end
  desc "List all nodes which have they state not in synch with they comment. (SITE=)"
  task :tofix => [:environment,:api_sites] do
    @logger.level = Logger::ERROR
    @tofix = true
    Rake::Task["deadnodes:browse"].execute
  end

  task :browse do
    def comment_ok?(comment)
      comment == "OK"
    end
    phoenix = []
    @api_sites.each do |site|
      reg = /^([^-]+)-(\d+)/
      site.status["nodes"].sort{|a,b|
        a_cluster,a_id = a[0].scan(reg).flatten
        b_cluster,b_id = b[0].scan(reg).flatten
        [a_cluster,a_id.to_i] <=> [b_cluster,b_id.to_i]
      }.each do |uid,status|
        comment = status["comment"]
        state = status["hard"].downcase
        if comment_ok?(comment)
          if state == "dead"
            @logger.error "Node '#{uid}' of state '#{state}' should not have comment '#{comment}'" if @tofix
          else
            # nothing, good state
          end
        else
          if state == "dead"
            @logger.info "Node '#{uid}' is dead because '#{comment}'" if @reasons
          else
            @logger.error "Node '#{uid}' should have the not-dead-comment 'OK', since its state is '#{state}'. Instead, it has comment '#{comment}'." if @tofix
            phoenix.push uid if comment.match(/^\[phoenix\]/) != nil
          end
        end
      end
    end
    puts phoenix if ENV["PHOENIX"] == "yes"
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

      command = ""

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
          command.concat("oarnodesetting -h #{host} ")
          command.concat(" -p ").concat( export.to_a.map{|(k,v)|
            if v.nil?
              nil
            else
              "#{k}=#{v.inspect.gsub("'", "\\'").gsub("\"", "'")}"
            end
          }.compact.join(" -p ") )
        else              # new file
          node_number = node_uid.split("-")[1]
          command.concat("oar_resources_add -H 1 --host0 #{node_number} --host-prefix #{cluster_uid}- --host-suffix .#{site_uid}.#{grid_uid}.fr -C #{node.properties['architecture']['smp_size']} -c #{export['cpucore']}")
          command.concat(" -a")
          # Add other properties
          command.concat(' -A "')
          if ENV['MAINTENANCE'] && ENV['MAINTENANCE']=='NO'
            command.concat(' -p maintenance=\'NO\'')
          else
            # by default, maintenance is YES when creating new resources
            command.concat(' -p maintenance=\'YES\'')
          end
          # by default, an Alive node has comment "OK"
          command.concat(' -p comment=\'OK\'')
          command.concat(" -p ").concat( export.to_a.map{|(k,v)|
            if v.nil?
              nil
            else
              "#{k}=#{v.inspect.gsub("'", "\\'").gsub("\"", "'")}"
            end
          }.compact.join(" -p ") )
          command.concat('"')
        end
      when "D"            # deletion of a file
        command.concat("oarnodesetting -s Dead -h #{host}")
      else
        @logger.warn "Don't know what to do with #{line.inspect}. Ignoring."
        next
      end

      if ENV['COMMIT'] && ENV['COMMIT']=='YES'
        command.concat(' -c')
      end

      commands << command
    end
    commands.each do |command|
      puts command
    end
  end
end

namespace :netlinks do
  desc "Generates network API JSON files based on net-links yaml files.\nUse DRY=yes to simulate the execution. "
  task :generate => [:environment,:hosts] do
    host,site = @host.scan(/(\S+)\.(\S+)/).flatten
    root_dir_input = File.join(ROOT_DIR, "generators","input")
    command = File.join(ROOT_DIR, "generators", "grid5000")
    command += " " + File.join(root_dir_input, "net-links.rb")
    command += " " + File.join(root_dir_input,"sites", site,"#{site}.rb")
    command += " " + File.join(root_dir_input,"sites", site,"net-links","#{host}.yaml")

    command << " -s" if ENV['DRY'] == "yes"
#    puts command
    sh command
  end
end
namespace :env do
  desc "Generates environment JSON files .\nUse DRY=yes to simulate the execution. "
  task :generate => [:environment] do
    env_name = ENV["ENV_NAME"]
    abort "You must provide ENV_NAME=" if env_name.nil?
    root_dir_input = "#{ROOT_DIR}/generators/input"
    command = File.join(ROOT_DIR, "generators", "grid5000")
    command += " " + File.join(root_dir_input, "environments","#{env_name}")

    command << " -s" if ENV['DRY'] == "yes"
    sh command
  end
end
namespace :weathermap do
  @weathermap_options = ""
  task :hosts do
    @weathermap_site = ENV['SITE']
    @weathermap_host = ENV['HOST']
    abort "You must provide the SITE= " if @weathermap_site.nil?
    abort "You must provide the HOST= name (uid) in its site " if @weathermap_host.nil? or @weathermap_host.match(/\.grid5000\.fr/) != nil
  end
  task :execute => ["weathermap:hosts"]  do
    cmd = "bundle exec weathermap"
    cmd += " --site '#{@weathermap_site}' --host '#{@weathermap_host}' --api-path #{ROOT_DIR} #{@weathermap_options}"
    sh cmd
  end
  desc "Create weathermaps for host HOST without data."
  task :testing => ["weathermap:hosts"]  do
    @weathermap_options.replace("--action write --use-cacti no")
    Rake::Task['weathermap:execute'].invoke
  end
  desc "Create weathermaps for host HOST with RRD from cacti."
  task :production => ["weathermap:hosts"]  do
    @weathermap_options.replace("--action write --use-cacti yes")
    Rake::Task['weathermap:execute'].invoke
  end
  desc "Display network links description amongst network equipments."
  task :display do
    @weathermap_options.replace("--action display")
    Rake::Task['weathermap:execute'].invoke
  end
end
