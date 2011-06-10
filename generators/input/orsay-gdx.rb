require 'net/ssh'

def switch_match_node(switch,id); switch != nil and (switch[:nodes][0] <= id and id <= switch[:nodes][1]); end
def get_switch_for_node(switches,id)
  switches.each{|k,v| 
    arr = v.split(",").map{|s| s.to_i}
    next if id < arr[0] or arr[1] < id
    return lookup('orsay-network',k).merge({:nodes=>arr})
  }
  lookup('orsay-network',"switch-nil").merge({:nodes=>[0,0]})
end

site :orsay do |site_uid|
  ssh = Net::SSH.start("frontend.#{site_uid}.grid5000.fr","g5kadmin")
  
  cluster :gdx do |cluster_uid|
    model "IBM eServer 326m"
    created_at nil
    misc "bios:1.28/bcm:1.20.17/bmc:1.10/rsaII:1.00"
    
    # WARN: 2 nodes are missing (gdx-311 and gdx-312) and won't appear in the reference
    1.upto(180+132-2) do |i| 
      switch_eth0 = get_switch_for_node lookup("orsay-links","links-eth0","gdx"), i unless switch_match_node switch_eth0, i
      switch_bmc = get_switch_for_node lookup("orsay-links","links-bmc","gdx"), i unless switch_match_node switch_bmc, i
      switch_rsa = get_switch_for_node lookup("orsay-links","links-rsa","gdx"), i unless switch_match_node switch_rsa, i
      switch_mx = get_switch_for_node lookup("orsay-links","links-mx","gdx"), i unless switch_match_node switch_mx, i
      
      node "#{cluster_uid}-#{i}" do |node_uid|
    
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
        network_adapters [{
            :interface => 'Ethernet',
            :device => 'bmc',
            :rate => (eval switch_bmc["rate"]),
            :mac => lookup('orsay-gdx', "#{node_uid}", 'mac_bmc'),
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5780',
            :enabled => true,
            :management => true,
            :mountable => false,
            :mounted => false,
            :network_address => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
            :ip => dns_lookup_through_ssh(ssh,"#{node_uid}-bmc.#{site_uid}.grid5000.fr"),
            :switch => (switch_bmc["name"]+".#{site_uid}.grid5000.fr"),
            :switch_ip => switch_bmc["ip"],
            :switch_mac => switch_bmc["mac"],
            :switch_console => (switch_rsa["name"]+".#{site_uid}.grid5000.fr"),
            :switch_console_ip => switch_rsa["ip"],
            :switch_console_mac => switch_rsa["mac"]
          },{
            :interface => 'Myrinet',
            :device => 'myri0',
            :rate => (eval switch_mx["rate"]),
            :mac => lookup('orsay-gdx', "#{node_uid}", 'mac_mx'),
            :vendor => 'Myrinet',
            :version => '10G-PCIE-8A-C',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => "mx_driver",
            :mounted => true,
            :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
            :ip => dns_lookup_through_ssh(ssh,"#{node_uid}-myri0.#{site_uid}.grid5000.fr"),
            :switch => (switch_mx["name"]+".#{site_uid}.grid5000.fr"),
            :switch_ip => switch_mx["ip"],
            :switch_mac => switch_mx["mac"]
          },{
            :interface => 'Ethernet',
            :device => 'eth0',
            :rate => (eval switch_eth0["rate"]),
            :mac => lookup('orsay-gdx', "#{node_uid}", 'mac_eth0'),
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5780',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'tg3',
            :mounted => true,
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :ip => dns_lookup_through_ssh(ssh,"#{node_uid}.#{site_uid}.grid5000.fr"),
            :switch => (switch_eth0["name"]+".#{site_uid}.grid5000.fr"),
            :switch_ip => switch_eth0["ip"],
            :switch_mac => switch_eth0["mac"]
          },{
            :interface => 'Ethernet',
            :device => 'eth1',
            :rate => 0,
            :mac => lookup('orsay-gdx', "#{node_uid}", 'mac_eth1'),
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5780',
            :enabled => false,
            :management => false,
            :mountable => false,
            :driver => 'tg3',
            :mounted => false,
            :network_address => "#{node_uid}-eth1.#{site_uid}.grid5000.fr",
            :ip => dns_lookup_through_ssh(ssh,"#{node_uid}-eth1.#{site_uid}.grid5000.fr"),
            :switch => nil,
            :switch_ip => nil,
            :switch_mac => nil
          }]
      end        
    end
    
    # extension specifics, starting at node 181
    (181).upto(306) do |i|
      node "#{cluster_uid}-#{i}" do
        processor({
          :version => "250",
          :clock_speed => 2.4.G
        })
      end
    end
    
  end # cluster gdx
  
  ssh.close
end
