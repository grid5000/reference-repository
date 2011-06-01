require 'net/ssh'
site :orsay do |site_uid|
  ssh = Net::SSH.start("frontend.#{site_uid}.grid5000.fr","g5kadmin")
  
  cluster :gdx do |cluster_uid|
    model "IBM eServer 326m"
    created_at nil
    misc "bios:1.28/bcm:1.20.17/bmc:1.10/rsaII:1.00"
    
    # WARN: 2 nodes are missing (gdx-311 and gdx-312) and won't appear in the reference
    1.upto(180+132-2) do |i|
      node "#{cluster_uid}-#{i}" do |node_uid|
        rack_uid = node_uid.split("-")[1].to_i / 18
    
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
            :rate => (eval lookup('orsay-network', "switch-bmc-#{rack_uid/2}", 'rate')),
            :mac => lookup('orsay-gdx', "#{node_uid}", 'mac_bmc'),
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5780',
            :enabled => true,
            :management => true,
            :mountable => true,
            :mounted => true,
            :network_address => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
            :ip => dns_lookup_through_ssh(ssh,"#{node_uid}-bmc.#{site_uid}.grid5000.fr"),
            :switch => (lookup('orsay-network', "switch-bmc-#{rack_uid/2}", 'name')+".#{site_uid}.grid5000.fr"),
            :switch_ip => lookup('orsay-network', "switch-bmc-#{rack_uid/2}", 'ip'),
            :switch_mac => lookup('orsay-network', "switch-bmc-#{rack_uid/2}", 'mac'),
            :switch_console => (lookup('orsay-network', "switch-rsa-#{rack_uid/2}", 'name')+".#{site_uid}.grid5000.fr"),
            :switch_console_ip => lookup('orsay-network', "switch-rsa-#{rack_uid/2}", 'ip'),
            :switch_console_mac => lookup('orsay-network', "switch-rsa-#{rack_uid/2}", 'mac'),
          },{
            :interface => 'Myrinet',
            :device => 'myri0',
            :rate => (eval lookup('orsay-network', "switch-mx", 'rate')),
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
            :switch => (lookup('orsay-network', "switch-mx", 'name')+".#{site_uid}.grid5000.fr"),
            :switch_ip => lookup('orsay-network', "switch-mx", 'ip'),
            :switch_mac => lookup('orsay-network', "switch-mx", 'mac')
          },{
            :interface => 'Ethernet',
            :device => 'eth0',
            :rate => (eval lookup('orsay-network', "switch-eth0-#{rack_uid}", 'rate')),
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
            :switch => (lookup('orsay-network', "switch-eth0-#{rack_uid}", 'name')+".#{site_uid}.grid5000.fr"),
            :switch_ip => lookup('orsay-network', "switch-eth0-#{rack_uid}", 'ip'),
            :switch_mac => lookup('orsay-network', "switch-eth0-#{rack_uid}", 'mac'),
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
    (181).upto(312-2) do |i|
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
