require 'rubygems'
require 'cmd-line-script'
require 'snmp'
require 'resolv'


#host = "gw"
#community = "public@600"
#mac_port_oids = ["1.3.6.1.2.1.17.4.3.1.1", "1.3.6.1.2.1.17.4.3.1.2"]
#bridge_oid = "1.3.6.1.2.1.17.1.4.1.2"
#ifname_oid = "1.3.6.1.2.1.31.1.1.1.1"
#
#ports = Hash.new
#
#SNMP::Manager.open(:Host => host, :Community => community) do |manager|
#  manager.walk(mac_port_oids) do |mac, port|
#    bridge = String.new
#    ifname = String.new
#    mac_addr = mac.value.unpack("H2H2H2H2H2H2").join(":")
#    res = manager.get(bridge_oid + "." + port.value.to_s)
#    res.each_varbind do |var|
#      bridge = var.value.to_s
#    end
#    unless bridge == "noSuchInstance"
#      res = manager.get(ifname_oid + "." + bridge)
#      res.each_varbind do |var|
#        ifname = var.value.to_s
#      end
#    end
#    #ifname = manager.get(ifname_oid + "." + bridge.value.to_s)
#    ports[mac_addr] = ifname
#  end
#end

module MIB
  module Cisco
    def reload
      @vlans                = "1.3.6.1.4.1.9.9.46.1.3.1.1.2"
      @macs                 = "1.3.6.1.2.1.17.4.3.1.1"
      @bridges              = "1.3.6.1.2.1.17.4.3.1.2"
      @ifindexes            = "1.3.6.1.2.1.17.1.4.1.2"
      @ifnames              = "1.3.6.1.2.1.31.1.1.1.1"
      @arp_table            = "1.3.6.1.2.1.4.22.1.2"

      @mac_port_oids        = ["1.3.6.1.2.1.17.4.3.1.1", "1.3.6.1.2.1.17.4.3.1.2"]
      @bridge_oid           = "1.3.6.1.2.1.17.1.4.1.2"
      @ifname_oid           = "1.3.6.1.2.1.31.1.1.1.1"
      @no_such_instance     = "noSuchInstance"
    end
    def wrong_response?(var)
      var.value.to_s == @no_such_instance
    end
  end
  class MIB 
    attr_reader :mac_port_oids,:bridge_oid,:ifname_oid,:no_such_instance
    attr_reader :vlans,:macs,:bridges,:ifindexes,:ifnames,:arp_table
    def initialize(model,logger)
      @logger = logger
      @model = model
      case @model
      when "cisco"; self.extend(Cisco);
      when "aspen","extreme-networks","extremenetworks"; self.extend(MIB::ExtremeNetworks);
      when "procurve","hp-procurve","hpprocurve"; self.extend(MIB::HPProcurve);
      when "foundry"; self.extend(MIB::Foundry);
      else
        abort "Router model '#{@model}' is unknown"
      end
      reload
    end
  end
end



class NetLinks
  attr_reader :host,:model
  def initialize(host,community,logger)
    @logger = logger
    @host = host
    @community = community
  end
  def set_model(model)
    @mib = MIB::MIB.new(model,@logger)
    @model = model
  end
  def walk_interfaces
    vlans = []
    # Find all available vlans
    SNMP::Manager.open(:Host => @host, :Community => @community,:Retries => 2) do |snmp|
      snmp.walk(@mib.vlans) do |vlan|
        vlan = vlan.name[-1]
        vlans.push vlan unless vlan > 999
      end
    end
    @logger.info  "Found '#{vlans.size}' vlans on host '#{@host}'"
    # chose a vlan to probe
    ports = []
    vlans.each do |vlan_id|
#      next unless vlan_id == 536
      @logger.info  "Probing vlan #{vlan_id}"
      vlan_community = "#{@community}@#{vlan_id}"
      macs = []
      SNMP::Manager.open(:Host => @host, :Community => vlan_community,:Retries => 2) do |snmp|
        # Find mac addresses in this vlan
        snmp.walk(@mib.macs) do |var|
          uid = var.name[-1]
          mac = var.value.unpack("H2H2H2H2H2H2").join(":").strip
          @logger.debug "Found mac = #{mac}"

          # Associate a bridge port to each mac address in this vlan
          macs_oid = @mib.macs.split(/\./).map{|s|s.to_i}
          mac_uid = (var.name.to_a - macs_oid).join(".")
          snmp.get("#{@mib.bridges}.#{mac_uid}").each_varbind do |var|
            next if @mib.wrong_response? var
            bridge = var.value.to_i
            @logger.debug "Found bridge = #{bridge}"

            # Associate a ifindex to each bridge port
            snmp.get("#{@mib.ifindexes}.#{bridge}").each_varbind do |var|
              next if @mib.wrong_response? var
              ifindex = var.value.to_i
              @logger.debug "Found ifindex = #{ifindex}"

              # Associate an ifName to each ifindex
              snmp.get("#{@mib.ifnames}.#{ifindex}").each_varbind do |var|
                next if @mib.wrong_response? var
                ifname = var.value.to_s.strip
                @logger.debug "Found ifname = #{ifname}"
                macs.push({:mac=>mac,:ifname=>ifname,:vlan=>vlan_id})
              end
            end
          end
        end
      end
      if macs.empty?
        @logger.warn "Failed to find any neighbors on vlan '#{vlan_id}'"
      else
        @logger.info "Found '#{macs.size}' neighbors on vlan '#{vlan_id}'"
        # Ensure unicity of mac addresse and interface
        macs.each do |mac|
          ex = ports.find{|p| p[:mac] == mac[:mac] and p[:ifname] == mac[:ifname]}
          if ex.nil?
            ex = mac
            ex[:vlans] = []
            ports.push ex
          end
          ex[:vlans].push mac.delete(:vlan)
        end
      end
    end
    @logger.info "Summary : found '#{ports.size}' neighbors on '#{vlans.size}' vlans"
    @ports = ports
  end
  def fill_ip
    # submit an arp command
    arp_table = []
    SNMP::Manager.open(:Host => @host, :Community => @community,:Retries => 2) do |snmp|
      snmp.walk(@mib.arp_table) do |var|
        ip = var.name.to_a[-4,4].join('.')
        mac = var.value.unpack("H2H2H2H2H2H2").join(":").strip
        arp_table.push({:ip=>ip,:mac=>mac})
      end
    end
    @logger.info "Found '#{arp_table.size}' items in arp table."
    count = 0
    arp_table.each do |arp|
      @ports.each do |macs|
        next if macs[:mac] != arp[:mac]
        macs.merge! arp
        count += 1
      end
    end
    @logger.info "Found '#{count}' IP addresses for neighbors "
  end
  def fill_fqdn
    count = 0
    @ports.each do |macs|
      begin 
        macs[:fqdn] = Resolv.getname(macs[:ip])
        count += 1
      rescue Resolv::ResolvError => e
      end
    end
    @logger.info "Found '#{count}' FQDN throuth DNS requests"
  end

  def save_to_yaml(file)
    file = File.expand_path(file)
    if File.exists?(file)
      @logger.info "Found file '#{file}' already existing, it will simply be updated."
      # Load the content in the file
      existing = YAML::load_file(file)
      # Merge with what we found
#      macs = existing.dup
      count_updated = count_new = count_was_there_but_absent_now = 0
      existing.each do |ex|
#        puts ex.inspect
        mac = @ports.find{|p| p[:mac] == ex[:mac] and p[:ifname] == ex[:ifname] }
        if mac.nil?
          count_was_there_but_absent_now += 1
        else
          count_updated += 1
          ex.merge!(@ports.delete(mac))
        end
      end
      count_new = @ports.size
      @ports.concat(existing)
      @logger.info "New='#{count_new}'; Updated='#{count_updated}'; WasThereButAbsentNow='#{count_was_there_but_absent_now}' => Total is '#{@ports.size}'"
    end
    @ports.each do |mac|
      duup = @ports.dup
      duup.delete(mac)
      if duup.any?{|p| p[:mac] == mac[:mac]}
        @logger.error "double found #{mac.inspect}"
        abort "Existing now"
      end
    end
    # Save all in the file
    File.open(file,'w') {|f| YAML::dump(@ports,f)}
    @logger.info "File Saved at '#{file}'"
  end
end

class NetLinksEngine < CmdLineScript
  def parse!(args)
    super(args,[:host,nil,:model,nil,:community,nil,:output,nil])
    @logger = @options.delete(:logger)
  end
  def run!
    netlinks = NetLinks.new(@options[:host],@options[:community],@logger)
    netlinks.set_model(@options[:model])
    netlinks.walk_interfaces
    netlinks.fill_ip
    netlinks.fill_fqdn
    netlinks.save_to_yaml(File.join(File.expand_path(@options[:output]),"#{netlinks.host}.yaml"))
  end
  def option_host(opt_sym,opt_str,opt_dft)
    opt_dft ||= "gw"
    @opt_parser.on("#{opt_str}=", "The network equipment [default=#{opt_dft}].") do |s|
      @options[opt_sym] = s 
    end
    opt_dft
  end
  def option_model(opt_sym,opt_str,opt_dft)
    opt_dft ||= "cisco"
    @opt_parser.on("#{opt_str}=", "The network equipment's model [default=#{opt_dft}].") do |s|
      @options[opt_sym] = s 
    end
    opt_dft
  end

  def option_community(opt_sym,opt_str,opt_dft)
    opt_dft ||= "public"
    @opt_parser.on("#{opt_str}=", "The SNMP community [default=#{opt_dft}].") do |s|
      @options[opt_sym] = s 
    end
    opt_dft
  end
  def option_output(opt_sym,opt_str,opt_dft)
    opt_dft ||= "/tmp"
    @opt_parser.on("#{opt_str}=", "The output directory [default=#{opt_dft}].") do |s|
      @options[opt_sym] = s 
    end
    opt_dft
  end
end
