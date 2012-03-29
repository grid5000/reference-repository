require 'rubygems'
require 'fileutils'
require 'json'
require 'logger'
require 'yaml'
require 'pp'

ROOT_DIR = File.expand_path File.dirname(__FILE__)
LIB_DIR = File.join(ROOT_DIR, "generators", "lib")
$LOAD_PATH.unshift(LIB_DIR) unless $LOAD_PATH.include?(LIB_DIR)

EXTRA_DIR = File.join(ROOT_DIR, "extra", "lib")
$LOAD_PATH.unshift(EXTRA_DIR) unless $LOAD_PATH.include?(EXTRA_DIR)

Rake.application.options.trace = true


require 'grid5000'
require 'naming-pattern'

task :environment do
  Dir.chdir(ROOT_DIR)
  @logger = Logger.new(STDERR)
  @logger.level = Logger.const_get((ENV['DEBUG'] || 'INFO').upcase)
end

namespace :netlinks do
  desc "Probe a remote network equipement and retrieve its neighbors in a yaml file. HOST is its grid5000 FQDN."
  task :probe do 
    host = ENV['HOST']
    abort "You must provide HOST= the network equipment FQDN within grid5000" if host.nil?
    scan = host.scan(/^([^.]+)\.([^.]+)$/)
    scan = host.scan(/^([^.]+)\.([^.]+)\.grid5000\.fr$/) if scan.empty?
    abort "HOST is on the form 'gw.lille' or 'gw.lille.grid5000.fr'" if scan.empty?
    uid,site = scan.flatten
    # copy the 'extra' dir on the site,
    # execute the probing
    # retrieve the result
    prober = "weathermap.#{site}.grid5000.fr"
    sh "rsync -av extra #{prober}:"
    sh "ssh #{prober} 'cd extra && bundle install && ./bin/net-links.rb --host #{uid} --community public'"
    sh "rsync -av #{prober}:/tmp/#{uid}.yaml generators/input/#{site}/net-links/"

    message = "Network links saved into file generators/input/#{site}/net-links/#{uid}.yaml"
    puts "+-#{"-" * message.size}-+"
    puts "| #{message} |"
    puts "+-#{"-" * message.size}-+"
  end
  def format_vlan(coord,raw_port,linecards)
        puts "Vlan : #{coord.inspect} #{raw_port.inspect}"
  end
  def format_channel(coord,raw_port,linecards)
#        puts "Channel : #{coord.inspect} #{raw_port.inspect}"
  end
  def format_port(coord,raw_port,linecards)
#    puts "#{coord.inspect} #{raw_port.inspect}"
    return unless raw_port.has_key? :fqdn
    neighbor,site = raw_port[:fqdn].scan(/([^.]+)\.([^.]+)\.grid5000\.fr/).flatten
    return if neighbor.nil?

    l = coord["linecard"]
    p = coord["port"]
    linecards[l] = {"ports"=>{}} unless linecards.has_key? l
    ports = linecards[l]["ports"]
    formated_port = ports[p]
    if formated_port.nil?
      ports[p] = neighbor
    elsif formated_port.is_a? Hash
      ports[p]["uid"] = neighbor
    else
      ports[p] = neighbor
    end
  end
  def browse_naming_patterns(dico,cb,patterns)
    dico.each do |key,value|
      if value.is_a? Hash
        browse_naming_patterns(value,cb,patterns)
      else
        if key == "naming_pattern"
          pattern = value
          if patterns.has_key? pattern
            @logger.warn "Naming Pattern already defined '#{pattern}'. No redefinition possible." 
          else
            patterns[pattern] = cb
          end
        end
      end
    end
  end

  desc "Updated formated net-links with the raw information gathered from network equipments."
  task :format => :environment do
    # Read the network links fresh out of network equipment
    # Read the configuration formated
    # update the formated configuration with raw information from the net-links yaml file
    site = ENV['SITE']
    abort "You must provide SITE= " if site.nil?
    formated_file = "generators/input/#{site}/net-links.yaml"
    formated_all = YAML::load_file(formated_file)
    Dir.glob("generators/input/#{site}/net-links/*.yaml").each do |raw_file|
      uid = File.basename(raw_file).scan(/(\S+).yaml$/).first.first
      next unless uid == "gw"
      formated = formated_all[uid]
      if formated.nil?
        @logger.warn "Network Equipment '#{uid}' was not found in formated network links file '#{formated_file}'. Skiping"
        next
      end
      raw = YAML::load_file(raw_file)

      # Go through all formated config, and register a call back that will encode the naming_pattern
      naming_patterns = {}
      vlans = formated["vlans"]
      vlans_cb = proc { |dict,raw_port|
            format_vlan(dict,raw_port,vlans)
          }
      browse_naming_patterns(vlans,vlans_cb,naming_patterns)
      channels = formated["channels"]
      channels_cb = proc { |dict,raw_port|
            format_channel(dict,raw_port,channels)
          }
      browse_naming_patterns(channels,channels_cb,naming_patterns)

      linecards = formated["linecards"]
      linecards_cb = proc { |dict,raw_port|
            format_port(dict,raw_port,linecards)
          }
      browse_naming_patterns(linecards,linecards_cb,naming_patterns)

      # Go through all ports to find they linecard and port index, 
      raw.each do |port|
        ifname = port[:ifname]
        next if ifname.nil?
        # find the naming_pattern that correspond to this ifname
        naming_patterns.each do |np,cb|
          # scan the ifname with each naming_pattern
          dict = NamingPattern.encode(np,ifname)
          unless dict.empty?
            # Found the naming_pattern for this ifname
            # So Place it where it belongs
            cb.call(dict,port)
            break
          end
        end
        #
      end
    end
    File.open(formated_file,'w'){|f| YAML::dump(formated_all,f)}
#    pp formated_all
    message = "Formated Network links saved into file generators/input/#{site}/net-links.yaml"
    puts "+-#{"-" * message.size}-+"
    puts "| #{message} |"
    puts "+-#{"-" * message.size}-+"

  end
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
          command.concat(" -a /node=#{host}/cpu={#{node.properties['architecture']['smp_size']}}/core={#{export['cpucore']}}")
          command.concat(" --auto-offset")
          if ENV['MAINTENANCE'] && ENV['MAINTENANCE']=='NO'
            command.concat(' -p maintenance="NO"')
          else
            # by default, maintenance is YES when creating new resources
            command.concat(' -p maintenance="YES"')
          end
        end
        command.concat(" -p ").concat( export.to_a.map{|(k,v)|
          if v.nil?
            nil
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
