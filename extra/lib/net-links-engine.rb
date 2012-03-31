require 'rubygems'
require 'cmd-line-script'
require 'snmp'
require 'resolv'
#require 'pp'


module MIB
  module Cisco
    def reload
      @vlans                = "1.3.6.1.4.1.9.9.46.1.3.1.1.2"
      @macs                 = "1.3.6.1.2.1.17.4.3.1.1"
      @bridges              = "1.3.6.1.2.1.17.4.3.1.2"
      @ifindexes            = "1.3.6.1.2.1.17.1.4.1.2"
      @ifnames              = "1.3.6.1.2.1.31.1.1.1.1"
      @arp_table            = "1.3.6.1.2.1.4.22.1.2"

#"cdpCtAddressTable"       "1.3.6.1.4.1.9.9.23.1.2.2"
#"cdpCacheTable"           "1.3.6.1.4.1.9.9.23.1.2.1"
#"cdpCacheEntry"           "1.3.6.1.4.1.9.9.23.1.2.1.1"
#"cdpCacheIfIndex"         "1.3.6.1.4.1.9.9.23.1.2.1.1.1"
#"cdpCacheDeviceIndex"     "1.3.6.1.4.1.9.9.23.1.2.1.1.2"
#"cdpCacheAddressType"     "1.3.6.1.4.1.9.9.23.1.2.1.1.3"    123.4 = INTEGER: 1
#"cdpCacheAddress"         "1.3.6.1.4.1.9.9.23.1.2.1.1.4"    123.4 = Hex-STRING: AC 11 2F C9
#"cdpCacheVersion"         "1.3.6.1.4.1.9.9.23.1.2.1.1.5"    123.4 = STRING: "Cisco IOS Software, C2960 Software (C2960-LANBASE-M), Version 12.2(35)SE5, RELEASE SOFTWARE (fc1)
#Copyright (c) 1986-2007 by Cisco Systems, Inc.
#Compiled Thu 19-Jul-07 20:06 by nachen"
#"cdpCacheDeviceId"        "1.3.6.1.4.1.9.9.23.1.2.1.1.6"    123.4 = STRING: "sw-admin1.lille.grid5000.fr"
#"cdpCacheDevicePort"      "1.3.6.1.4.1.9.9.23.1.2.1.1.7"    123.4 = STRING: "GigabitEthernet0/47"
#"cdpCachePlatform"        "1.3.6.1.4.1.9.9.23.1.2.1.1.8"    123.4 = STRING: "cisco WS-C2960G-48TC-L"
#"cdpCacheCapabilities"    "1.3.6.1.4.1.9.9.23.1.2.1.1.9"    123.4 = Hex-STRING: 00 00 00 28
#"cdpCacheVTPMgmtDomain"   "1.3.6.1.4.1.9.9.23.1.2.1.1.10"   123.4 = STRING: "g5klille"
#"cdpCacheNativeVLAN"      "1.3.6.1.4.1.9.9.23.1.2.1.1.11"   123.4 = INTEGER: 1
#"cdpCacheDuplex"          "1.3.6.1.4.1.9.9.23.1.2.1.1.12"   123.4 = INTEGER: 3
#"cdpCacheApplianceID"     "1.3.6.1.4.1.9.9.23.1.2.1.1.13"
#"cdpCacheVlanID"          "1.3.6.1.4.1.9.9.23.1.2.1.1.14"

      @cdp_device_id          = "1.3.6.1.4.1.9.9.23.1.2.1.1.6"  #     123.4 = STRING: "sw-admin1.lille.grid5000.fr"
      @cdp_device_port        = "1.3.6.1.4.1.9.9.23.1.2.1.1.7"  #     123.4 = STRING: "GigabitEthernet0/47"
      @cdp_device_platform    = "1.3.6.1.4.1.9.9.23.1.2.1.1.8"  #     123.4 = STRING: "cisco WS-C2960G-48TC-L"
      @cdp_global_device_id   = "1.3.6.1.4.1.9.9.23.1.3.4"      #     0  = STRING: "gw-lille-6k.grid5000.fr"
      @cdp_ifnames            = "1.3.6.1.4.1.9.9.23.1.1.1.1.6"  #     123 = STRING: "GigabitEthernet4/23"


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
#    attr_reader :mac_port_oids,:bridge_oid,:ifname_oid,:no_such_instance
    attr_reader :vlans,:macs,:bridges,:ifindexes,:ifnames,:arp_table
    attr_reader :cdp_ifnames,:cdp_global_device_id,:cdp_device_platform,:cdp_device_port,:cdp_device_id
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
  def walk_cdp
    # for cisco :  .1.3.6.1.4.1.9.9.23.1
    cdp = {}
    SNMP::Manager.open(:Host => @host, :Community => @community,:Retries => 2) do |snmp|
      to_walk = {:uid=>@mib.cdp_device_id,:remote_port=>@mib.cdp_device_port,:platform => @mib.cdp_device_platform}
      to_walk.each do |key,oid|
        snmp.walk(oid) do |sn|
          ifindex = sn.name[-2].to_i
          cdp[ifindex] = {} unless cdp.has_key? ifindex
          cdp[ifindex][key] = sn.value.to_s
        end
      end
      cdp.each do |ifindex,port|
        snmp.get("#{@mib.cdp_ifnames}.#{ifindex}").each_varbind do |var|
          next if @mib.wrong_response? var
          port[:ifname] = var.value.to_s
        end
        port[:remote_port].replace(port[:remote_port].gsub(/TenGigabitEthernet/,"Te").gsub(/GigabitEthernet/,"Gi"))
        port[:ifname].replace(port[:ifname].gsub(/TenGigabitEthernet/,"Te").gsub(/GigabitEthernet/,"Gi")) if port.has_key? :ifname

      end
    end
    @cdp = cdp.values
    if @cdp.empty?
      @logger.warn "Failed to find any neighbor with CDP protocol"
    else 
      @logger.info "Found '#{@cdp.size}' neighbors by using CDP protocol"
    end
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
        @logger.info "Failed to find any neighbors on vlan '#{vlan_id}'"
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
    # Get the ARP table on the router
    arp_table = []
    SNMP::Manager.open(:Host => @host, :Community => @community,:Retries => 2) do |snmp|
      snmp.walk(@mib.arp_table) do |var|
        ip = var.name.to_a[-4,4].join('.')
        mac = var.value.unpack("H2H2H2H2H2H2").join(":").strip
        arp_table.push({:ip=>ip,:mac=>mac})
      end
    end
    @logger.info "Found '#{arp_table.size}' items in arp table."

    # Then match each ip <-> mac found with all the mac addresses we already have
    count = 0
    arp_table.each do |arp|
      @ports.each do |macs|
        next if macs[:mac] != arp[:mac]
        macs.merge! arp
        count += 1
      end
    end

    # Then resolv the names we found with cdp protocol
    @cdp.each do |cdp|
      uid = cdp[:uid]
      begin
        cdp[:ip] = Resolv.getaddress(uid)
        count += 1
      rescue Resolv::ResolvError => e
        @logger.error "Resolve dns error : #{uid.inspect} => #{e.message}"
      end
    end
    @logger.info "Found '#{count}' IP addresses for neighbors "
  end
  def fill_fqdn
    count = 0
    # Reverse resolv IP learn previously with arp
    @ports.each do |macs|
      ip = macs[:ip]
      next if ip.nil?
      begin 
        macs[:fqdn] = Resolv.getname(ip)
        count += 1
      rescue Resolv::ResolvError => e
        @logger.error "Reverse dns error : #{ip.inspect} => #{e.message}"
      end
    end
    # Then reverse IP found during cdp probing
    @cdp.each do |cdp|
      ip = cdp[:ip]
      next if ip.nil?
      begin
        cdp[:fqdn] = Resolv.getname(ip)
        # The uid is not useful anymore here since we have the fqdn
        cdp.delete(:uid)
        count += 1
      rescue Resolv::ResolvError => e
        @logger.error "Reverse dns error : #{ip.inspect} => #{e.message}"
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
      count_updated = count_new = count_was_there_but_absent_now = 0
      existing.each do |ex|
        # Look if this existing entry has been found again on the network
        mac = @ports.find{|p| p[:mac] == ex[:mac] and p[:ifname] == ex[:ifname] }
        if mac.nil?
          # Look if this existing entry is still on the CDP network
          mac = @cdp.find{|p| p[:ifname] == ex[:ifname] and p[:remote_port] == ex[:remote_port]}
          if mac.nil?
            count_was_there_but_absent_now += 1
          else
            count_updated += 1
            ex.merge!(@cdp.delete(mac))
          end
        else
          count_updated += 1
          ex.merge!(@ports.delete(mac))
        end
      end
      count_new = @ports.size + @cdp.size
      @ports.concat(existing + @cdp)
      @logger.info "New='#{count_new}'; Updated='#{count_updated}'; WasThereButAbsentNow='#{count_was_there_but_absent_now}' => Total is '#{@ports.size}'"
    end
    @ports.each do |mac|
      duup = @ports.dup
      duup.delete(mac)
      if duup.any?{|p| 
          if p.has_key? :mac
            p[:mac] == mac[:mac] 
          elsif p.has_key? :remote_port
            p[:ifname] == mac[:ifname] and p[:remote_port] == mac[:remote_port] 
          else
            false
          end
        }
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
    netlinks.walk_cdp
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
