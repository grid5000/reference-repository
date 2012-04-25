require 'rubygems'
require 'fileutils'
require 'json'
require 'logger'
require 'yaml'
require 'pp'

ROOT_DIR = File.expand_path File.dirname(__FILE__)
LIB_DIR = File.join(ROOT_DIR, "generators", "lib")
$LOAD_PATH.unshift(LIB_DIR) unless $LOAD_PATH.include?(LIB_DIR)

EXTRA_DIR = File.join(ROOT_DIR, "extras")
EXTRA_DIR_LIB = File.join(EXTRA_DIR, "lib")
$LOAD_PATH.unshift(EXTRA_DIR_LIB) unless $LOAD_PATH.include?(EXTRA_DIR_LIB)

Rake.application.options.trace = true

require 'grid5000'
require 'naming-pattern'

task :environment do
  Dir.chdir(ROOT_DIR)
  @logger = Logger.new(STDERR)
  @logger.level = Logger.const_get((ENV['DEBUG'] || 'INFO').upcase)
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

namespace :netlinks do
  desc "Probe a remote network equipement and retrieve its neighbors in a yaml file. HOST is its grid5000 FQDN."
  task :probe => [:environment,:hosts] do 
    # Scan the site net-links yaml file to find properties about this host (snmp community,...)
    # These properties are going to be used to probe the given host
    host,site = @host.scan(/(\S+)\.(\S+)/).flatten
    dirs = Dir.glob("generators/input/#{site}/")
    if dirs.empty?
      @logger.error "Failed to find a directory containing the net-links yaml file for your site '#{site}'"
      next
    end
    message = []
    dirs.each do |dir|
      site = File.basename(dir)
      net_links_file = File.join(dir,"net-links.yaml")
      net_links_dir = File.join(dir,"net-links")
      probes = []

      net_links = YAML::load_file(net_links_file)
      net_links.each do |host_uid,properties|
        next if host_uid.match(Regexp.new(host.gsub(/\*/,'\S+'))).nil?
        # gather information about this host
        probes.push({:uid=>host_uid, :snmp_community => properties["snmp_community"]})
      end
      if probes.empty?
        @logger.warn "Failed to find any host described within the file #{net_links_file}."
      else
        # copy the 'extra' dir on the site,
        # execute all the probing on all hosts
        # retrieve the result from all hosts
        extra_dir_basename = File.basename(EXTRA_DIR)
        prober = "weathermap.#{site}.grid5000.fr"
        sh "rsync -av #{EXTRA_DIR} #{prober}:"
        sh "ssh #{prober} 'cd #{extra_dir_basename} && http_proxy=http://proxy:3128 bundle install'"

        probes.each do |info|
          sh "ssh #{prober} 'cd #{extra_dir_basename} && ./bin/net-links.rb --host #{info[:uid]} --community #{info[:snmp_community]} --logger stdout:warn'"
        end
        probes.each do |info|
          sh "rsync -av #{prober}:/tmp/#{info[:uid]}.yaml #{net_links_dir}/"
          message.push "* #{net_links_dir}/#{info[:uid]}.yaml"
        end
      end
    end
    # Print the result on a pretty message
    if message.empty?
      @logger.warn "No host net-link has been download locally. Please correct warnings first."
    else
      message.unshift "Network links were saved into the following files : "
      message_size = message.max{|a,b|a.size <=> b.size}.size
      puts "+-#{"-" * message_size}-+"
      puts message.map{|m| "| #{m} "}.join("\n")
      puts "+-#{"-" * message_size}-+"
    end
  end
  def format_vlan(coord,raw_port,linecards)
#        puts "Vlan : #{coord.inspect} #{raw_port.inspect}"
  end
  def format_channel(coord,raw_port,linecards)
#        puts "Channel : #{coord.inspect} #{raw_port.inspect}"
  end
  def format_port(coord,raw_port,linecards)
#    puts "#{coord.inspect} #{raw_port.inspect}"
    neighbor,port,site = nil
    if raw_port.has_key? :fqdn
      neighbor,site = raw_port[:fqdn].scan(/([^.]+)\.([^.]+)\.grid5000\.fr/).flatten
    elsif raw_port.has_key? :uid
      if ((scan = raw_port[:uid].scan(/([^.]+)\.([^.]+)\.grid5000\.fr/)).size > 0)
        neighbor,site = scan.flatten
      else
        neighbor = raw_port[:uid]
      end
      port = raw_port[:port]
    end
    return if neighbor.nil?

    l = (coord["linecard"]||0)
    p = coord["port"]
    linecards[l] = {"ports"=>{}} unless linecards.has_key? l
    ports = linecards[l]["ports"]
    formated_port = ports[p]
    if formated_port.nil? and port.nil?
      ports[p] = neighbor
    elsif formated_port.is_a? Hash
      ports[p]["uid"] = neighbor
      ports[p]["port"] = port unless port.nil?
    else
      if port.nil?
        ports[p] = neighbor
      else
        ports[p] = {"uid"=>neighbor,"port"=>port}
      end
    end
  end
  def browse_naming_patterns(dico,patterns,&block)
    dico.each do |key,value|
      if value.is_a? Hash
        browse_naming_patterns(value,patterns,&block)
      else
        if key == "naming_pattern"
          pattern = value
          if patterns.has_key? pattern
            @logger.warn "Naming Pattern already defined '#{pattern}'. Skipping this redefinition." 
          else
            patterns[pattern] = block
          end
        end
      end
    end
  end

  desc "Updated formated net-links with the raw information gathered from network equipments."
  task :format => [:environment,:hosts] do
    # Read the network links fresh out of network equipment
    # Read the configuration formated
    # update the formated configuration with raw information from the net-links yaml file
    host,site = @host.scan(/(\S+)\.(\S+)/).flatten
    dirs = Dir.glob("generators/input/#{site}/")
    if dirs.empty?
      @logger.error "Failed to find a directory containing the net-links yaml file for your site '#{site}'"
      next
    end
    message = []
    dirs.each do |dir|
      site = File.basename(dir)
      net_links_file = File.join(dir,"net-links.yaml")
      net_links_dir = File.join(dir,"net-links")

      net_links = YAML::load_file(net_links_file)
      hosts = {}
      net_links.each do |uid,properties|
        hosts[uid] = properties unless uid.match(Regexp.new(host.gsub(/\*/,'\S+'))).nil?
      end
      if hosts.empty?
        @logger.warn "Failed to find any host described within the file #{net_links_file}."
      else
        # Read the network links fresh out of network equipment
        # Read the configuration formated
        # update the formated configuration with raw information from the net-links yaml file
        hosts.each do |uid,properties|
          raw_file = File.join(net_links_dir,"#{uid}.yaml")
          raw = YAML::load_file(raw_file)

          # Go through all formated config, and register a call back that will encode the naming_pattern
          patterns = {}
          browse_naming_patterns(properties["vlans"],patterns) do  |dict,raw_port|
            format_vlan(dict,raw_port,properties["vlans"])
          end
          browse_naming_patterns(properties["channels"],patterns) do  |dict,raw_port|
            format_channel(dict,raw_port,properties["channels"])
          end
          browse_naming_patterns(properties["linecards"],patterns) do |dict,raw_port|
            format_port(dict,raw_port,properties["linecards"])
          end

          # Go through all ports to find they linecard and port index, 
          raw.each do |port|
            ifname = port[:ifname]
            next if ifname.nil?
            # find the naming_pattern that correspond to this ifname
            patterns.each do |np,cb|
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
        # When all net links in a site are formated, we write them in they file.
        File.open(net_links_file,'w'){|f| YAML::dump(net_links,f)}
        message.push "#{net_links_file} hosts=#{hosts.keys.inspect}"
      end
    end
    # Print the result on a pretty message
    if message.empty?
      @logger.warn "No host net-link has been formated. Please correct warnings and your cli parameters."
    else
      message.map!{|m| "* #{m}"}
      message.unshift "Formated Network links were saved into the following files : "
      message_size = message.max{|a,b|a.size <=> b.size}.size
      puts "+-#{"-" * message_size}-+"
      puts message.map{|m| "| #{m} "}.join("\n")
      puts "+-#{"-" * message_size}-+"
    end
  end
  task :net_links => [:environment,:hosts] do
    host,site = @host.scan(/(\S+)\.(\S+)/).flatten
    dirs = Dir.glob("generators/input/#{site}/")
    if dirs.empty?
      @logger.error "Failed to find a directory containing the net-links yaml file for your site '#{site}'"
      next
    end
    @equipments = dirs.map do |dir|
      site = File.basename(dir)
      net_links_file = File.join(dir,"net-links.yaml")
      net_links_dir = File.join(dir,"net-links")

      net_links_orig = YAML::load_file(net_links_file)
      net_links = net_links_orig.select do |uid,properties|
        uid.match(Regexp.new(host.gsub(/\*/,'\S+'))) != nil
      end
      if net_links.empty?
        @logger.warn "Failed to find any host described within the file #{net_links_file}."
      else
        {:net_links => net_links,:net_links_orig => net_links_orig,:net_links_file=>net_links_file}
      end
    end
  end
  desc "Manually modify net-links.yaml with custumized script."
  task :manual => :net_links do
#    puts @net_links.inspect
    # gw.grenoble
    gw = @equipments[0]
    puts gw[:net_links]
    linecards = gw[:net_links]["sbordeplage-2"]["linecards"][1]
    linecards["ports"] = {} if linecards["ports"].nil?
    ports = linecards["ports"]
    11.upto(51) do |i|
      ports[i-10] = "bordeplage-#{i}"
    end
    # When all net links in a site are formated, we write them in they file.
    File.open(gw[:net_links_file],'w'){|f| YAML::dump(gw[:net_links_orig].merge(gw[:net_links]),f)}
    puts "updated #{gw[:net_links_file]}"

  end

  desc "Update net-links.yaml with the kavlan like config file."
  task :kavlan => [:environment,:hosts] do
    config_file = ENV['CONF']
    abort "You must provide a CONF=, which is the path to the kavlan like config file." if config_file.nil?
    host,site = @host.scan(/(\S+)\.(\S+)/).flatten
    dirs = Dir.glob("generators/input/#{site}/")
    if dirs.empty?
      @logger.error "Failed to find a directory containing the net-links yaml file for your site '#{site}'"
      next
    end
    message = []
    dirs.each do |dir|
      site = File.basename(dir)
      net_links_file = File.join(dir,"net-links.yaml")
      net_links_dir = File.join(dir,"net-links")

      net_links_orig = YAML::load_file(net_links_file)
      net_links = net_links_orig.select do |uid,properties|
        uid.match(Regexp.new(host.gsub(/\*/,'\S+'))) != nil
      end
      if net_links.empty?
        @logger.warn "Failed to find any host described within the file #{net_links_file}."
      else
        # parse the kavlan like config file
        # #newservices 9/2 FastIron
        config = {}
        File.read(config_file).lines.each do |line|
          if ((scan = line.strip.scan(/^([^.]+)\.([^.]+)\.grid5000\.fr\s+(\S+)\s+(\S+)$/)).size > 0)
              
            uid,site,ifname,router = scan.flatten
            router = router.downcase
            config[router] = [] unless config.has_key? router
            port = {:ifname=>ifname}
            if ((scan = uid.scan(/^([^-]+)-([^-]+)-(\S+)$/)).size>0)
              cluster,node_id,iface = scan.flatten
              port[:uid] = "#{cluster}-#{node_id}"
              port[:port] = iface
            else
              port[:uid] = uid
            end
            config[router].push(port)
          end
        end

        updated = []
        # Update the net-links with kavlan config file
        net_links.each do |uid,properties|
          router = config[uid]
          next if router.nil?
          updated.push uid
          # register interfaces naming patterns
          patterns = {}
          browse_naming_patterns(properties["linecards"],patterns) do |dict,raw_port|
            format_port(dict,raw_port,properties["linecards"])
          end
          # parse the ifname
          router.each do |neighbor|
            ifname = neighbor[:ifname]
            # find the naming_pattern that correspond to this ifname
            patterns.each do |np,cb|
              # scan the ifname with each naming_pattern
              dict = NamingPattern.encode(np,ifname)
              unless dict.empty?
                # Found the naming_pattern for this ifname
                # So Place it where it belongs
                cb.call(dict,neighbor)
                break
              end
            end
          end
        end
        # When all net links in a site are formated, we write them in they file.
        File.open(net_links_file,'w'){|f| YAML::dump(net_links_orig.merge(net_links),f)}
        message.push "#{net_links_file} hosts=#{updated.inspect}"
      end
    end
    # Print the result on a pretty message
    if message.empty?
      @logger.warn "No host net-link has been formated. Please correct warnings and/or your cli parameters."
    else
      message.map!{|m| "* #{m}"}
      message.unshift "Formated Network links were saved into the following files : "
      message_size = message.max{|a,b|a.size <=> b.size}.size
      puts "+-#{"-" * message_size}-+"
      puts message.map{|m| "| #{m} "}.join("\n")
      puts "+-#{"-" * message_size}-+"
    end
  end
  desc "Generates The JSON files that will be used for network API.\nUse DRY=1 to simulate the execution. "
  task :generate => [:environment,:hosts] do
    host,site = @host.scan(/(\S+)\.(\S+)/).flatten
    dirs = Dir.glob("generators/input/#{site}/")
    if dirs.empty?
      @logger.error "Failed to find a directory containing the net-links yaml file for your site '#{site}'"
      next
    end
    generator = "#{File.join(ROOT_DIR, "generators", "grid5000")}"
    net_link_generator = "#{File.join(ROOT_DIR, "generators", "input", "net-links-generator.rb")}"
    dirs.each do |dir|
      site = File.basename(dir)
      net_links_file = File.expand_path(File.join(dir,"net-links.yaml"))
      command = "#{generator}  #{net_link_generator} #{net_links_file}"
      command << " -s" if ENV['DRY'] && ENV['DRY'] != "0"
      sh command
    end

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
