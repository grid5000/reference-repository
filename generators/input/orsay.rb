def node_switch(clusters,switch,node)
  cluster,uids,iface = node.split("-")
  clusters[cluster] = [] unless  clusters.has_key? cluster
  min,max = uids.split(",").map{|s| s.to_i}
  nodes = clusters[cluster]
  min.upto(max) {|id|
    nodes[id] = {} if nodes[id].nil?
    ifaces = nodes[id]
    fail "nodes #{cluster}-#{id} already has switch for iface '#{iface}' : #{ifaces.inspect} " unless ifaces[iface].nil?
    ifaces[iface] = switch
  }
end
def cluster_node_switch(clusters,switch)
  switch.each{|sw,v0|
#    puts "sw = #{sw} ; v0 = #{v0}"
    if v0.has_key? "nodes"
      if v0["nodes"].is_a? String
        node_switch clusters, sw, v0["nodes"]
      elsif v0["nodes"].is_a? Array
        v0["nodes"].each{|node| node_switch clusters,sw,node} 
      else
        fail "Nodes must be String or Array."
      end
    end
    if v0.has_key? "next"
      v0["next"].each{|sw| cluster_node_switch clusters,sw}
    end
  }
end

def update_switch(switches,iface,sw_name)
  unless switches.has_key? iface and switches[iface]["name"] == sw_name
    sw = lookup('orsay-network',sw_name) 
    fail "Switch '#{sw_name}' not found in 'orsay-network'" if sw.nil?
    if sw["rate-in"].nil? 
      fail "Switch '#{sw_name}' input rate must be defined : 'rate' or 'rate-in'" if sw["rate"].nil?
      sw["rate-in"] = sw["rate"]
    end
    if sw["rate-out"].nil? 
      fail "Switch '#{sw_name}' output rate must be defined : 'rate' or 'rate-out'" if sw["rate"].nil?
      sw["rate-out"] = sw["rate"]
    end
    sw["name"] = sw_name
    switches[iface] = sw
  end
end
def fill_net_ifaces(site_uid,cluster_uid,node_uid,ifaces,switches)
  net_ifaces = []
  ifaces.each{|iface,sw_name|
    next if iface == "rsa"

    node = lookup("#{site_uid}-#{cluster_uid}", "#{node_uid}")
    fail "Node #{node_uid} not found in configuration '#{site_uid}-#{cluster_uid}'" if node.nil?
  
    net =   {
      :interface => (case iface;when "myri0";'Myrinet';else;"Ethernet";end),
      :device => iface,
      :rate => (eval switches[iface]["rate-in"]),
      :mac => node[iface]["mac"],
      :vendor => (case iface;when "myri0";'Myrinet';else;'Broadcom';end),
      :version => (case iface;when "myri0";'10G-PCIE-8A-C';else;'NetXtreme BCM5780';end),
      :enabled => (case iface;when "eth1";false;else;true;end),
      :management => (case iface;when "bmc";true;else;false;end),
      :mountable => (case iface;when "myri0","eth0";true;else;false;end),
      :mounted => (case iface;when "myri0","eth0";true;else;false;end),
      :driver => (case iface;when "myri0";'mx_driver';else;'tg3';end),
      :network_address => (case iface;when "eth0";"#{node_uid}.#{site_uid}.grid5000.fr";else;"#{node_uid}-#{iface}.#{site_uid}.grid5000.fr";end),
      :ip => node[iface]["ip"],
      :switch =>  ((switches[iface]["name"] == "switch-nil") ? (nil) : (switches[iface]["name"]+".#{site_uid}.grid5000.fr")),
      :switch_ip => switches[iface]["ip"],
      :switch_mac => switches[iface]["mac"]
    } 
    
    if net[:device] == "bmc"
      net.merge!({
      :switch_console => (switches["rsa"]["name"]+".#{site_uid}.grid5000.fr"),
      :switch_console_ip => switches["rsa"]["ip"],
      :switch_console_mac => switches["rsa"]["mac"]
      })
    end
    net_ifaces.push(net)
  }  
  net_ifaces
end

site :orsay do |site_uid|
  name "Orsay"
  location "Orsay, France" 
  web "https://www.grid5000.fr/mediawiki/index.php/Orsay:Home"
  description ""
  latitude 48.7000
  longitude 2.2000
  email_contact "orsay-staff@lists.grid5000.fr"
  sys_admin_contact "orsay-staff@lists.grid5000.fr"
  security_contact "orsay-staff@lists.grid5000.fr"
  user_support_contact "orsay-staff@lists.grid5000.fr"
  
  links = lookup("orsay-links","switch-to-switch")
#  puts links.inspect
  clusters = {}
  links.each{|sw,v| cluster_node_switch clusters,{sw => v}}
#  puts clusters.inspect
  
  cluster :gdx do |cluster_uid|
    model "IBM eServer 326m"
    created_at nil
    misc "bios:1.28/bcm:1.20.17/bmc:1.10/rsaII:1.00"

    switches = {}
    clusters[cluster_uid].each.each_with_index {|ifaces, id|
      next if ifaces.nil?
      ifaces.each{|iface,sw_name| update_switch switches, iface, sw_name }
      
      node "#{cluster_uid}-#{id}" do |node_uid|
        cmts = lookup('orsay-gdx', "#{node_uid}", 'comments')
        comments cmts unless cmts.nil?
            
        supported_job_types({:deploy => true, :besteffort => true, :virtual => false})
        architecture({
          :smp_size => 2, 
          :smt_size => 2,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "AMD",
          :model => "AMD Opteron",
          :version => ( (180 < id and id < 307 ) ? "250" : "246"),
          :clock_speed => ( (180 < id and id < 307 ) ? 2.4.G : 2.G),
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 1.MiB
        })
        main_memory({
          :ram_size => 2.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => "debian-x64-5-prod",
          :release => "5.1.2",
          :version => "5",
          :kernel   => "2.6.26"
        })
        storage_devices [
          {:interface => 'SATA', :size => 80.GB, :driver => "sata_svw"}
          ]

        network_adapters (fill_net_ifaces(site_uid,cluster_uid,node_uid,ifaces,switches))
      end        
    }
  end
  
  cluster :netgdx do |cluster_uid|
    model "IBM eServer 326m"
    created_at nil
    misc "bios:1.28/bcm:1.20.17/bmc:1.10/rsaII:1.00"

    switches = {}
    clusters[cluster_uid].each.each_with_index {|ifaces, id|
      next if ifaces.nil?
      ifaces.each{|iface,sw_name| update_switch switches, iface, sw_name }

      node "#{cluster_uid}-#{id}" do |node_uid|
        cmts = lookup('orsay-netgdx', "#{node_uid}", 'comments')
        comments cmts unless cmts.nil?
        
        supported_job_types({:deploy => true, :besteffort => true, :virtual => false})
        architecture({
          :smp_size => 2, 
          :smt_size => 2,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "AMD",
          :model => "AMD Opteron",
          :version => "246",
          :clock_speed => 2.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 1.MiB
        })
        main_memory({
          :ram_size => 2.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => "debian-x64-5-prod",
          :release => "5.1.2",
          :version => "5",
          :kernel   => "2.6.26"
        })
        storage_devices [
          {:interface => 'SATA', :size => 80.GB, :driver => "sata_svw"}
          ]

        network_adapters (fill_net_ifaces(site_uid,cluster_uid,node_uid,ifaces,switches))      
      end
    }
  end
end
