site :lille do |site_uid|

  cluster :chicon do |cluster_uid|
    model "IBM eServer 326m"
    created_at nil
    26.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => false})
        architecture({
          :smp_size => 2,
          :smt_size => 4,
          :platform_type => "x86_64"
        })
        processor({
          :vendor => "AMD",
          :model => "AMD Opteron",
          :version => "285",
          :clock_speed => 2.6.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 1.MiB
        })
        main_memory({
          :ram_size => 4.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => "Debian",
          :release => "6.0",
          :version => nil,
          :kernel => "2.6.32"
        })
        storage_devices [
          {:interface => 'SATA', :size => 80.GB, :driver => "sata_svw"}
        ]
        network_adapters [{
          :interface => 'Ethernet',
          :rate => 1.G,
          :mac => lookup('lille-chicon',"#{node_uid}", 'mac_eth0'),
          :vendor => 'Broadcom',
          :version => 'NetXtreme BCM5780',
          :enabled => true,
          :management => false,
          :mountable => true,
          :driver => 'tg3',
          :mounted => true,
          :device => 'eth0',
          :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr",
          :ip => lookup('lille-chicon',"#{node_uid}", 'ip_eth0'),
          :switch => 'gw'
        },{
          :interface => 'Ethernet',
          :rate => 1.G,
          :mac => lookup('lille-chicon',"#{node_uid}", 'mac_eth1'),
          :vendor => 'Broadcom',
          :version => 'NetXtreme BCM5780',
          :enabled => true,
          :management => false,
          :mountable => true,
          :driver => 'tg3',
          :mounted => true,
          :device => 'eth1',
          :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip => lookup('lille-chicon',"#{node_uid}", 'ip_eth1'),
          :switch => 'gw',
          :switch_port => lookup('lille-chicon', "#{node_uid}", 'switch_port')
        },{
          :interface => 'Ethernet',
          :rate => 1.G,
          :mac => lookup('lille-chicon',"#{node_uid}", 'mac_mgt'),
          :vendor => 'IBM',
          :version => '1.18',
          :enabled => true,
          :management => true,
          :mountable => false,
          :network_address => "#{node_uid}-rsa.#{site_uid}.grid5000.fr",
          :ip => lookup('lille-chicon',"#{node_uid}", 'ip_mgt'),
          :switch => 'gw'
        },{
          :interface => 'Myrinet',
          :rate => 10.G,
          :mac => nil,
          :vendor => "Myricom",
          :version => "10G-PCIE-8A-C",
          :enabled => true,
          :management => false,
          :mountable => true,
          :driver => 'mx',
          :mounted => true,
          :device => 'myri0',
          :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
          :ip => lookup('lille-chicon',"#{node_uid}", 'ip_myri0'),
          :switch => nil
        }]
      end
    end
  end # cluster chicon

end
