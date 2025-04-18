# See also: https://www.grid5000.fr/w/DNS_server

require 'dns/zone'
require 'find'
require 'ipaddr'

#Prettier aligned dump of records
class DNS::Zone::RR::A
  def dump
    max_pad = 30
    return "#{@label.ljust(max_pad)} IN A #{' ' * 6 + @address}"
  end
end

class DNS::Zone::RR::AAAA
  def dump
    max_pad = 30
    return "#{@label.ljust(max_pad)} IN AAAA #{' ' * 6 + @address}"
  end
end

class DNS::Zone::RR::CNAME
  def dump
    max_pad = 30
    return @label.ljust(max_pad) + " IN CNAME " + ' ' * 6 + @domainname
  end
end

class DNS::Zone::RR::NS
  def dump
    max_pad = 30
    return @label.ljust(max_pad) + " IN NS " + ' ' * 6 + @nameserver
  end
end

class DNS::Zone::RR::MX
  def dump
    max_pad = 30
    return @label.ljust(max_pad) + " MX " + @priority.to_s + " " * 6 + @exchange
  end
end

class DNS::Zone::RR::SOA
  #Keep the previous version of soa format
  def dump
    content = "@" + " " * 23 + "IN      SOA     "
    content += @nameserver + " "
    content += @email + " (\n"
    content += " " * 32 + @serial.to_s + " ; serial (YYYYMMDDSS)\n"
    content += " " * 32 + @refresh_ttl + " " * 9 + "; refresh\n"
    content += " " * 32 + @retry_ttl + " " * 9 + "; retry\n"
    content += " " * 32 + @expiry_ttl + " " * 9 + "; expire\n"
    content += " " * 32 + @minimum_ttl + ")" + " " * 8 + "; negative caching\n"
    return content
  end
end

class DNS::Zone

  attr_accessor :file_path
  attr_accessor :site_uid
  attr_accessor :header
  attr_accessor :soa
  attr_accessor :ns_list
  attr_accessor :mx
  attr_accessor :at
  attr_accessor :include

  def get_header
    content = "; This file was generated by reference-repository.git\n; Do not edit this file by hand. Your changes will be overwritten.\n"
    if header
      content += "$TTL 3h\n"
      content += soa.dump + "\n"
      for ns in ns_list
        content += ns.dump + "\n"
      end
      if at
        content += at.dump + "\n"
      end
      if mx
        content += mx.dump + "\n"
      end
    end
    return content
  end

  #Re-define Zone dump
  def dump
    last_type = ""
    content = []
    if @include
      content << "\n" + @include
    end
    @records.each { |record|
      if record.type != last_type
        content << "\n; #{record.type} records"
      end
      content << record.dump
      last_type = record.type
    }
    return get_header() + content.join("\n") << "\n"
  end
end

def get_servers_records(site)
  records = []
  site['servers'].sort.each { |server_uid, server|

    next if server['network_adapters'].nil?

    server['network_adapters'].each { |net_uid, net|
      next if net['ip'].nil? && net['ip6'].nil?
      if net['ip']
        new_record = DNS::Zone::RR::A.new
        new_record.address = net['ip']
        new_record.label = server_uid
        new_record.label += "-#{net_uid}" if net_uid != 'default'
        records << new_record
      end
      if net['ip6']
        new_record_ipv6 = DNS::Zone::RR::AAAA.new
        new_record_ipv6.address = net['ip6']
        new_record_ipv6.label = server_uid
        new_record_ipv6.label += "-#{net_uid}" if net_uid != 'default'
        new_record_ipv6.label += '-ipv6'
        records << new_record_ipv6
      end
      if server['alias']
        #Reject global aliases (See 7513)
        server['alias'].reject{ |cname| cname.include?('.') }.each{ |cname|
          cname_record = DNS::Zone::RR::CNAME.new
          cname_record.label = cname
          cname_record.label += "-#{net_uid}" if net_uid != 'default'
          cname_record.domainname = server_uid
          cname_record.domainname += "-#{net_uid}" if net_uid != 'default'
          records << cname_record
        }
      end
    }
  }
  return records
end

def get_pdus_records(site)
  records = []

  site['pdus'].sort.each { |pdu_uid, pdu|

    next unless pdu['ip'] || pdu['ip6']

    if pdu['ip']
      new_record = DNS::Zone::RR::A.new
      new_record.address = pdu['ip']
      new_record.label = pdu_uid
      records << new_record
    end
    if pdu['ip6']
      new_record_ipv6 = DNS::Zone::RR::AAAA.new
      new_record_ipv6.address = pdu['ip6']
      new_record_ipv6.label = pdu_uid + '-ipv6'
      records << new_record_ipv6
    end
  }
  return records
end

def get_networks_records(site, key)
  records = []

  site[key].sort.each { |uid, net|
    if net['ip'].nil?
      puts "Warning: no IP for #{uid}"
      next
    end

    if net['ip']
      new_record = DNS::Zone::RR::A.new
      new_record.address = net['ip']
      new_record.label = uid
      records << new_record
    end
    if net['ip6']
      new_record_ipv6 = DNS::Zone::RR::AAAA.new
      new_record_ipv6.address = net['ip6']
      new_record_ipv6.label = uid + '-ipv6'
      records << new_record_ipv6
    end
    if net['alias']
      net['alias'].each{ |a|
        if a.is_a?(Hash)
          new_record = DNS::Zone::RR::A.new
          new_record.address = a['ip']
          new_record.label = a['name']
          records << new_record
          if a['ip6']
            new_record_ipv6 = DNS::Zone::RR::AAAA.new
            new_record_ipv6.address = a['ip6']
            new_record_ipv6.label = a['name'] + '-ipv6'
            records << new_record_ipv6
          end
        end
        if a.is_a?(String) and !a.include?('.')  #Reject global aliases (See 7513)
          cname_record = DNS::Zone::RR::CNAME.new
          cname_record.label = a
          cname_record.domainname = uid
          records << cname_record
        end
      }
    end
  }

  return records
end

def get_node_records(cluster_uid, node_uid, network_adapters)

  records = []

  network_adapters.each { |net_uid, net_hash|
    next unless net_hash['ip'] || net_hash['ip6']

    node_id = node_uid.to_s.split(/-/)[1].to_i # node number

    if net_hash['ip']
      new_record = DNS::Zone::RR::A.new
      new_record.address = net_hash['ip']
      new_record.label = "#{cluster_uid}-#{node_id}"
      new_record.label += "-#{net_uid}" unless net_hash['mounted'] && /^eth[0-9]$/.match(net_uid)
      records << new_record
      if /^eth[0-9]$/.match(net_uid) && !net_hash['pname'].nil? && !net_hash['pname'].empty? &&
         net_hash['pname'] != net_uid
        cname_record = DNS::Zone::RR::CNAME.new
        cname_record.label = "#{cluster_uid}-#{node_id}-#{net_hash['pname']}"
        cname_record.domainname = "#{cluster_uid}-#{node_id}-#{net_uid}"
        records << cname_record
      end
    end
    if net_hash['ip6']
      new_record_ipv6 = DNS::Zone::RR::AAAA.new
      new_record_ipv6.address = net_hash['ip6']
      new_record_ipv6.label = "#{cluster_uid}-#{node_id}"
      new_record_ipv6.label += "-#{net_uid}" unless net_hash['mounted'] && /^eth[0-9]$/.match(net_uid)
      new_record_ipv6.label += '-ipv6'
      records << new_record_ipv6
      if /^eth[0-9]$/.match(net_uid) && !net_hash['pname'].nil? && !net_hash['pname'].empty? &&
         net_hash['pname'] != net_uid
        cname_record_ipv6 = DNS::Zone::RR::CNAME.new
        cname_record_ipv6.label = "#{cluster_uid}-#{node_id}-#{net_hash['pname']}-ipv6"
        cname_record_ipv6.domainname = "#{cluster_uid}-#{node_id}-#{net_uid}-ipv6"
        records << cname_record_ipv6
      end
    end

    if net_hash['mounted'] && /^eth[0-9]$/.match(net_uid)
      # CNAME enabled for primary interface (node-id-iface cname node-id)
      if net_hash['ip']
        cname_record = DNS::Zone::RR::CNAME.new
        cname_record.label = "#{cluster_uid}-#{node_id}-#{net_uid}"
        cname_record.domainname = "#{cluster_uid}-#{node_id}"
        records << cname_record
      end
      if net_hash['ip6']
        cname_record_ipv6 = DNS::Zone::RR::CNAME.new
        cname_record_ipv6.label = "#{cluster_uid}-#{node_id}-#{net_uid}-ipv6"
        cname_record_ipv6.domainname = "#{cluster_uid}-#{node_id}-ipv6"
        records << cname_record_ipv6
      end
    end

    #Handle interface aliases 
    if (net_hash["alias"])
      net_hash["alias"].each { |cname|
        cname_record = DNS::Zone::RR::CNAME.new
        cname_record.label = "#{cluster_uid}-#{node_id}-#{cname}"
        cname_record.domainname = "#{cluster_uid}-#{node_id}-#{net_uid}"
        records << cname_record
      }
    end
  } #each network adapters
  return records
end

def get_node_kavlan_records(_cluster_uid, node_uid, network_adapters, kavlan_adapters)
  records = []

  kavlan_adapters.each { |net_uid, net_hash|

    next unless net_hash['ip'] || net_hash['ip6']

    net_primaries = network_adapters.select{ |u, h| h['mounted'] && /^eth[0-9]$/.match(u) } # list of primary interfaces
    net_uid_eth, net_uid_kavlan = net_uid.to_s.scan(/^([^-]*)-(.*)$/).first # split 'eth0-kavlan-1'

    if net_hash['ip']
      new_record = DNS::Zone::RR::A.new
      new_record.address = net_hash['ip']
      new_record.label = "#{node_uid}-#{net_uid}" #sol-23-eth0-kavlan-1
      records << new_record
      if !/^fpga[0-9]$/.match(net_uid_eth) && net_hash['pname'] != net_uid
        cname_record = DNS::Zone::RR::CNAME.new
        cname_record.label = "#{node_uid}-#{net_hash['pname']}"
        cname_record.domainname = "#{node_uid}-#{net_uid}" #sol-23-eno1-kavlan-1
        records << cname_record
      end
    end
    if net_hash['ip6']
      new_record_ipv6 = DNS::Zone::RR::AAAA.new
      new_record_ipv6.address = net_hash['ip6']
      new_record_ipv6.label = "#{node_uid}-#{net_uid}" #sol-23-eth0-kavlan-1
      new_record_ipv6.label += '-ipv6'
      records << new_record_ipv6
      if !/^fpga[0-9]$/.match(net_uid_eth) && net_hash['pname'] != net_uid
        cname_record_ipv6 = DNS::Zone::RR::CNAME.new
        cname_record_ipv6.label = "#{node_uid}-#{net_hash['pname']}-ipv6"
        cname_record_ipv6.domainname = "#{node_uid}-#{net_uid}-ipv6" #sol-23-eno1-kavlan-1
        records << cname_record_ipv6
      end
    end

    # CNAME only for primary interface kavlan
    if net_primaries.include?(net_uid_eth) and net_hash['ip']
      cname_record = DNS::Zone::RR::CNAME.new
      cname_record.label = "#{node_uid}-#{net_uid_kavlan}"
      cname_record.domainname = "#{node_uid}-#{net_uid}" #sol-23-eth0-kavlan-1
      records << cname_record
    end
    if net_primaries.include?(net_uid_eth) and net_hash['ip6']
      cname_record_ipv6 = DNS::Zone::RR::CNAME.new
      cname_record_ipv6.label = "#{node_uid}-#{net_uid_kavlan}-ipv6"
      cname_record_ipv6.domainname = "#{node_uid}-#{net_uid}-ipv6" #sol-23-eth0-kavlan-1
      records << cname_record_ipv6
    end
  } #each network adapters

  return records
end

def get_reverse_record(record, site_uid)

  return unless record.is_a?(DNS::Zone::RR::A) || record.is_a?(DNS::Zone::RR::AAAA)

  if record.is_a?(DNS::Zone::RR::AAAA) # check for AAAA before A because AAAA inherits from A (so an AAAA is also an A)
    nibble_array = IPAddr.new(record.address).to_string.gsub(':','').split('').reverse
    nibble_split = 16
    if /.*-kavlan-[1-9][0-9]-ipv6$/.match(record.label)
      nibble_split = 14
    end
    file_name = "reverse6-#{nibble_array[nibble_split..31].join('.')}.db"
    if /.*-kavlan-[1-3]-ipv6$/.match(record.label)
      #A filter in bind-global-site.conf.erb prevents entries in 'local' directory to be included in global configuration
      #TODO later, also add DMZ IPs check here
      file_name.prepend("local/")
    end
    reverse_record = DNS::Zone::RR::PTR.new
    reverse_record.label = nibble_array[0..(nibble_split-1)].join('.')
    reverse_record.name = "#{record.label}.#{site_uid}.grid5000.fr."
    return file_name, reverse_record
  elsif record.is_a?(DNS::Zone::RR::A)
    ip_array = record.address.split(".")
    file_name = "reverse-#{ip_array[0..2].reverse.join('.')}.db" # 70.16.172

    if /.*-kavlan-[1-3]$/.match(record.label)
      #A filter in bind-global-site.conf.erb prevents entries in 'local' directory to be included in global configuration
      #TODO later, also add DMZ IPs check here
      file_name.prepend("local/")
    end

    reverse_record = DNS::Zone::RR::PTR.new
    reverse_record.label = ip_array[3] #ip suffix
    reverse_record.name = "#{record.label}.#{site_uid}.grid5000.fr."

    return file_name, reverse_record
  end
end

def sort_records(records)
  sorted_records = []
  cnames = []
  in_a = []
  in_aaaa = []
  ptr = []

  records.each{ |record|
    if (record.is_a?(DNS::Zone::RR::AAAA)) # check for AAAA before A because AAAA inherits from A (so an AAAA is also an A)
      in_aaaa << record
    elsif (record.is_a?(DNS::Zone::RR::A))
      in_a << record
    elsif (record.is_a?(DNS::Zone::RR::CNAME))
      cnames << record
    elsif (record.is_a?(DNS::Zone::RR::PTR))
      ptr << record
    end
  }
  in_a.sort_by!{ |record|
    record.address.split('.').map{ |octet|
      octet.to_i
    }.push(record.label)
  }
  sorted_records += in_a
  in_aaaa.sort_by!{ |record|
    IPAddr.new(record.address).to_string.gsub(':','')
  }
  sorted_records += in_aaaa
  ptr.sort_by!{ |record|
    record.name
  }
  sorted_records += ptr
  #Sort CNAMES by node_id for node, node_id then kavlan number for node kavlan entry or finally by label
  cnames.sort_by!{ |record|
    sort_by = [ record.label ]
    label_array = record.label.split("-")
    if label_array.length > 1 and label_array[1] !~ /\D/ #only digit: must be something related to a node!
      sort_by = [ label_array[0] ]
      sort_by << (record.label.match(/ipv6/).nil? ? 0 : 1) # -ipv6 at end
      sort_by << label_array.length # sort by record 'type'
      sort_by << record.label.scan(/-(\d+)-?/).flatten.map{ |i| i.to_i} # sort by node then kavlan number
      intf = record.label.scan(/((eth|en)\w+)-?/).flatten.first # detect intf
      unless intf.nil?
        sort_by << (record.label.match(/eth/).nil? ? 1 : 0) # ethX first
        sort_by << intf.scan(/\d+/).reverse.map{ |i| i.to_i } # sort intf
      end
    end
    sort_by
  }
  sorted_records += cnames
  return sorted_records
end

# zone_type can be :internal or :external
def include_manual_file(zone, zone_type)
  manual_file_path = File.join(File.dirname(zone.file_path), File.basename(zone.file_path).sub('.db', '') + '-manual.db')
  if zone_type == :internal
    base_dir = "/etc/bind/zones"
  elsif zone_type == :external
    base_dir = "/etc/bind/zones/external"
  else
    raise "Zone type should be either :internal or :external"
  end
  if (File.exist?(manual_file_path))
    return "$INCLUDE #{base_dir}/#{zone.site_uid}/#{File.basename(zone.file_path).sub('.db', '') + '-manual.db'}\n"
  end
  return ''
end

# zone_type can be :internal or :external
def load_zone(zone_file_path, site_uid, site, zone_type, add_header)
  if File.exist?(zone_file_path)
    zone = DNS::Zone.load(File.read(zone_file_path))
  else
    zone = DNS::Zone.new
  end
  zone.site_uid = site_uid
  zone.file_path = zone_file_path
  #If the target file will have a header or not (manage included files without records duplication)
  zone.header = add_header
  zone.soa = zone.records[0] if zone.records.any? && zone.records[0].type == 'SOA'

  #We only want the zone to manage these records, we will manage SOA, MX, NS, @s manually
  zone.records.reject! { |rec|
    !( rec.is_a?(DNS::Zone::RR::A) || rec.is_a?(DNS::Zone::RR::CNAME) || rec.is_a?(DNS::Zone::RR::PTR)) || rec.label == "@"
  }
  if add_header && zone_type == :internal
    set_internal_zone_header_records(zone, site)
  elsif add_header && zone_type == :external
    set_external_zone_header_records(zone, site)
  end
  zone.include = include_manual_file(zone, zone_type)
  return zone
end

def set_internal_zone_header_records(zone, site)
  if zone.soa.nil?
    soa = DNS::Zone::RR::SOA.new
    soa.serial = Time.now.utc.strftime("%Y%m%d00")
    soa.refresh_ttl = "4h"
    soa.retry_ttl = "1h"
    soa.expiry_ttl = "4w"
    soa.minimum_ttl = "1h"
    soa.nameserver = "dns.grid5000.fr."
    soa.email = "nsmaster.dns.grid5000.fr."
    zone.soa = soa
  end
  ns = DNS::Zone::RR::NS.new
  ns.nameserver = "dns.grid5000.fr."
  zone.ns_list = [ns]
  # Only add MX for <site>.grid5000.fr, not for reverse zones
  if File.basename(zone.file_path) == "#{zone.site_uid}.db"
    zone.mx = DNS::Zone::RR::MX.new
    zone.mx.priority = 10
    zone.mx.exchange = "mail.#{zone.site_uid}.grid5000.fr."
  end
  if (File.basename(zone.file_path) == "#{zone.site_uid}.db" && site['frontend_ip'])
    zone.at = DNS::Zone::RR::A.new
    zone.at.address = site['frontend_ip']
  end
end

def set_external_zone_header_records(zone, _site)
  if zone.soa.nil?
    soa = DNS::Zone::RR::SOA.new
    soa.serial = Time.now.utc.strftime("%Y%m%d00")
    soa.refresh_ttl = "4h"
    soa.retry_ttl = "1h"
    soa.expiry_ttl = "1w"
    soa.minimum_ttl = "1h"
    soa.nameserver = "ns1.grid5000.fr."
    soa.email = "network-staff.lists.grid5000.fr."
    zone.soa = soa
  end
  ns1 = DNS::Zone::RR::NS.new
  ns1.nameserver = "ns1.grid5000.fr."
  ns2 = DNS::Zone::RR::NS.new
  ns2.nameserver = "ns2.grid5000.fr."
  ns3 = DNS::Zone::RR::NS.new
  ns3.nameserver = "ns-ext1.grid5000.fr."
  zone.ns_list = [ns1, ns2, ns3]
end

def update_serial(serial)
  date_serial = DateTime.strptime(serial.to_s, "%Y%m%d%S")
  now_date = DateTime.now
  if (date_serial.strftime("%Y%m%d") == now_date.strftime("%Y%m%d"))
    date_serial = date_serial + Rational(1, 86400) #+1 second
    return date_serial.strftime("%Y%m%d%S")
  else
    return Time.now.utc.strftime("%Y%m%d00")
  end
end

#Check if there are differences between existing and newly created records
#We check only A and CNAME records
def diff_zone_file(zone, records)
  #Compare dumped strings directly instead of RR objects
  zone_records = zone.records.map{ |rec|
    rec.dump
  }
  recs = records.map{ |rec|
    rec.dump
  }
  removed_records = zone_records - recs
  added_records = recs - zone_records
  if $options[:verbose]
    if removed_records.any?
      puts "Removed records in zone file: #{zone.file_path}"
      removed_records.each{ |rec|
        puts rec
      }
    end
    if added_records.any?
      puts "Added records in zone file: #{zone.file_path}"
      added_records.each{ |rec|
        puts rec
      }
    end
  end
  return added_records.any? || removed_records.any?
end

def write_site_conf(site_uid, dest_dir, zones_dir)
    conf_file = File.join(dest_dir, "#{site_uid}-zones.conf")
    FileUtils.mkdir_p(File.dirname(conf_file))
    conf_content = ERB.new(File.read(File.expand_path('templates/bind-site.conf.erb', File.dirname(__FILE__)))).result(binding)
    File.write(conf_file, conf_content)
end

def write_site_local_conf(site_uid, dest_dir, zones_dir)
    conf_file = File.join(dest_dir, "#{site_uid}-localzones.conf")
    FileUtils.mkdir_p(File.dirname(conf_file))
    # The 'local' folder is expected to exist by the bind-site-local erb template.
    FileUtils.mkdir_p(File.join(zones_dir, "local"))
    conf_content = ERB.new(File.read(File.expand_path('templates/bind-site-local.conf.erb', File.dirname(__FILE__)))).result(binding)
    File.write(conf_file, conf_content)
end

def write_site_external_conf(site_uid, dest_dir, zones_dir)
    conf_file = File.join(dest_dir, "#{site_uid}-zones.conf")
    FileUtils.mkdir_p(File.dirname(conf_file))
    conf_content = ERB.new(File.read(File.expand_path('templates/bind-site-external.conf.erb', File.dirname(__FILE__)))).result(binding)
    File.write(conf_file, conf_content)
end

def write_zone(zone)
  FileUtils.mkdir_p(File.dirname(zone.file_path))
  File.write(zone.file_path, zone.dump)
end

CLEAN_OLD_ZONE_FILES = false

# Type can be :internal (internal DNS data served to Grid5000) or
# :external (external DNS data served to the Internet)
def fetch_site_records(site, type)
  site_records = {}

  # This makes no sense (currently) for external DNS
  if type == :internal
    # Servers
    site_records['servers'] = get_servers_records(site) unless site['servers'].nil?

    # PDUs
    site_records['pdus'] = get_pdus_records(site) unless site['pdus'].nil?

    # Laptops (same input format as networks)
    site_records['laptops'] = get_networks_records(site, 'laptops') unless site['laptops'].nil?
  end

  # Add L3 network devices to both internal and external DNS, but only keep IPv6 records for external DNS.
  site_records['networks'] = get_networks_records(site, 'network_equipments') unless site['network_equipments'].nil?
  if type == :external
    site_records['networks'].select! { |record| record.is_a?(DNS::Zone::RR::AAAA) }
  end

  site.fetch("clusters", []).sort.each { |cluster_uid, cluster|

    cluster.fetch('nodes').select { |_node_uid, node|
      node != nil && node["status"] != "retired" && node.has_key?('network_adapters')
    }.each_sort_by_node_uid { |node_uid, node|

      network_adapters = {}

      # Nodes
      node.fetch('network_adapters').each { |net|
        network_adapters[net['device']] = {
          "ip6"     => net["ip6"],
          "mounted" => net["mounted"],
          'alias'   => net['alias'],
          'pname'   => net['name'],
        }
        network_adapters[net['device']]["ip"] = net["ip"] if type == :internal
      }

      # Mic
      if node['mic'] && (node['mic']['ip'] || node['mic']['ip6'])
        network_adapters['mic0'] = {"ip" => node['mic']['ip'], "ip6" => node['mic']['ip6']}
      end

      site_records[cluster_uid] ||= []
      site_records[cluster_uid] += get_node_records(cluster_uid, node_uid, network_adapters)

      # Kavlan
      kavlan_adapters = {}
      kavlan_kinds = ['kavlan6']
      kavlan_kinds << 'kavlan' if type == :internal
      kavlan_kinds.each { |kavlan_kind|
        if node[kavlan_kind]
          node.fetch(kavlan_kind).each { |net_uid, net_hash|
            net_hash.each { |kavlan_net_uid, ip|
              kavlan_adapters["#{net_uid}-#{kavlan_net_uid}"] ||= {}
              if /^eth[0-9]$/.match(net_uid)
                kavlan_adapters["#{net_uid}-#{kavlan_net_uid}"]['mounted'] = node['network_adapters'].select { |n|
                  n['device'] == net_uid
                }[0]['mounted']
                  kavlan_adapters["#{net_uid}-#{kavlan_net_uid}"]['pname'] = node['network_adapters'].select { |n|
                  n['device'] == net_uid
                  }.first['name'] + '-' + kavlan_net_uid
                if kavlan_kind == 'kavlan6'
                  kavlan_adapters["#{net_uid}-#{kavlan_net_uid}"]['ip6'] = ip
                else
                  kavlan_adapters["#{net_uid}-#{kavlan_net_uid}"]['ip'] = ip
                end
              end
              if /^fpga[0-9]$/.match(net_uid)
                kavlan_adapters["#{net_uid}-#{kavlan_net_uid}"]['mountable'] = node['network_adapters'].select { |n|
                  n['device'] == net_uid
                }[0]['moutable']
                if kavlan_kind == 'kavlan6'
                  kavlan_adapters["#{net_uid}-#{kavlan_net_uid}"]['ip6'] = ip
                else
                  kavlan_adapters["#{net_uid}-#{kavlan_net_uid}"]['ip'] = ip
                end
              end
            }
          }
        end
      }
      if kavlan_adapters.length > 0
        key_sr = "#{cluster_uid}-kavlan"
        site_records[key_sr] ||= []
        site_records[key_sr] += get_node_kavlan_records(cluster_uid, node_uid, network_adapters, kavlan_adapters)
      end
    } # each nodes
  } # each cluster

  site_records
end

# Returns one hash entry per reverse dns file
def compute_reverse_records(site_uid, site_records)
  reverse_records = {}

  site_records.each { |zone, records|
    # Sort records
    site_records[zone] = sort_records(records)

    records.each{ |record|
      # Get reverse records
      reverse_file_name, reverse_record = get_reverse_record(record, site_uid)
      if reverse_file_name != nil
        reverse_records[reverse_file_name] ||= []
        reverse_records[reverse_file_name].each {|r|
          if r.label == reverse_record.label
            puts "Warning: reverse entry with address #{reverse_record.label} already exists in #{reverse_file_name}, #{reverse_record.name} is duplicate"
          end
        }
        reverse_records[reverse_file_name] << reverse_record
      end
    }
  }

  reverse_records
end

def generate_internal_site_data(site_uid, site, dest_dir, zones_dir)
  if CLEAN_OLD_ZONE_FILES and File::exist?(zones_dir)
    # Cleanup of old zone files
    Find.find(zones_dir) do |path|
      next if not File::file?(path)
      next if path =~ /manual/ # skip *manual* files
      # FIXME those files are not named *manual*, but should not be removed
      next if ['nancy-laptops.db'].include?(File::basename(path))
      FileUtils::rm(path)
    end
  end

  site_records = fetch_site_records(site, :internal)

  # One hash entry per reverse dns file
  reverse_records = compute_reverse_records(site_uid, site_records)

  # Build all internal DNS zones
  internal_zones = []

  # Sort reverse records and create reverse zone from files
  reverse_records.each{ |file_name, records|
    if file_name.start_with?('reverse6')
      records.sort!{ |a, b|
        a.label.gsub('.','').reverse <=> b.label.gsub('.','').reverse
      }
    else
      records.sort_by!{ |r|
        [r.label.to_i, r.name]
      }
    end

    reverse_file_path = File.join(zones_dir, file_name)
    zone = load_zone(reverse_file_path, site_uid, site, :internal, true)
    if diff_zone_file(zone, records)
      zone.soa.serial = update_serial(zone.soa.serial)
    end
    zone.records = records;
    internal_zones << zone
  }

  # Manage site zone (SITE.db file)
  # It only contains header and inclusion of other db files
  # Check modification in included files and update serial accordingly
  site_zone_path = File.join(zones_dir, site_uid + ".db")
  site_zone = load_zone(site_zone_path, site_uid, site, :internal, true)
  site_zone_changed = false

  site_records.each{ |type, records|
    next if records.empty?
    zone_file_path = File.join(zones_dir, site_uid + "-" + type + ".db")
    zone = load_zone(zone_file_path, site_uid, site, :internal, false)
    if diff_zone_file(zone, records)
      puts "Internal zone file changed: #{zone.file_path}" if $options[:verbose]
      site_zone_changed = true
    end
    zone.records = records
    site_zone.include += "$INCLUDE /etc/bind/zones/#{site_uid}/#{File.basename(zone_file_path)}\n"
    internal_zones << zone
  }

  if (site_zone_changed)
    site_zone.soa.serial = update_serial(site_zone.soa.serial)
  end

  internal_zones << site_zone

  # zones that are already known and going to be written
  future_zones = internal_zones.map { |z| File::basename(z.file_path) }

  # Create reverse-*.db files for each reverse-*-manual.db that do not have (yet) a corresponding file.
  Dir.glob(File.join(zones_dir, "reverse-*-manual.db")).each { |reverse_manual_file|
    # FIXME: need to be adapted for IPv6 at some point
    output_file = reverse_manual_file.sub("-manual.db", ".db")
    next if future_zones.include?(File::basename(output_file)) # the zone is already going to be written
    puts "Creating file for orphan reverse manual file: #{output_file}" if $options[:verbose]
    # Creating the zone will include automatically the manual file
    zone = load_zone(output_file, site_uid, site, :internal, true)
    internal_zones << zone
  }

  internal_zones.each{ |zone|
    write_zone(zone)
  }

  write_site_conf(site_uid, dest_dir, zones_dir)
  write_site_local_conf(site_uid, dest_dir, zones_dir)
end

def generate_external_site_data(site_uid, site, dest_dir, zones_dir)
  site_records = fetch_site_records(site, :external)

  # One hash entry per reverse dns file
  reverse_records = compute_reverse_records(site_uid, site_records)

  # Build all external DNS zones (IPv6 only)
  external_zones = []

  # Sort reverse records and create reverse zone from files
  reverse_records.each{ |file_name, records|
    # Only keep IPv6 reverse zones
    next if not file_name.start_with?('reverse6')
    # Sort
    records.sort!{ |a, b|
      a.label.gsub('.','').reverse <=> b.label.gsub('.','').reverse
    }

    reverse_file_path = File.join(zones_dir, file_name)
    zone = load_zone(reverse_file_path, site_uid, site, :external, true)
    if diff_zone_file(zone, records)
      zone.soa.serial = update_serial(zone.soa.serial)
    end
    zone.records = records;
    external_zones << zone
  }

  # Manage site zone (SITE.db file)
  # It only contains header and inclusion of other db files
  # Check modification in included files and update serial accordingly
  site_zone_path = File.join(zones_dir, site_uid + ".db")
  site_zone = load_zone(site_zone_path, site_uid, site, :external, true)
  site_zone_changed = false

  site_records.each{ |type, records|
    next if records.empty?
    zone_file_path = File.join(zones_dir, site_uid + "-" + type + ".db")
    zone = load_zone(zone_file_path, site_uid, site, :external, false)
    if diff_zone_file(zone, records)
      puts "External zone file changed: #{zone.file_path}" if $options[:verbose]
      site_zone_changed = true
    end
    zone.records = records
    site_zone.include += "$INCLUDE /etc/bind/zones/external/#{site_uid}/#{File.basename(zone_file_path)}\n"
    external_zones << zone
  }

  if (site_zone_changed)
    site_zone.soa.serial = update_serial(site_zone.soa.serial)
  end

  external_zones << site_zone

  external_zones.each{ |zone|
    write_zone(zone)
  }

  write_site_external_conf(site_uid, dest_dir, zones_dir)
end

# main method
def generate_puppet_bindg5k(options)
  $options = options
  puts "Writing DNS configuration files to: #{$options[:output_dir]}"
  puts "For site(s): #{$options[:sites].join(', ')}"

  puts "Note: if you modify *-manual.db files you will have to manually update the serial in managed db file for changes to be applied"

  $written_files = []

  refapi = load_data_hierarchy

  # Loop over Grid'5000 sites
  refapi["sites"].each { |site_uid, site|
    next unless $options[:sites].include?(site_uid)

    internal_dest_dir = "#{$options[:output_dir]}/platforms/production/modules/generated/files/bind/"
    internal_zones_dir = File.join(internal_dest_dir, "zones/#{site_uid}")
    generate_internal_site_data(site_uid, site, internal_dest_dir, internal_zones_dir)

    external_dest_dir = "#{$options[:output_dir]}/platforms/production/modules/generated/files/bind_external/"
    external_zones_dir = File.join(external_dest_dir, "zones/#{site_uid}")
    generate_external_site_data(site_uid, site, external_dest_dir, external_zones_dir)
  } # each sites
end
