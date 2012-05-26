site :lyon do |site_uid|

  cluster :capricorne do |cluster_uid|
    model "IBM eServer 325"
    created_at Time.parse("2004-12-01 12:00 GMT").httpdate
    misc "bios: 1.36 / bcm: 1.20.9 / bmc: 1.46"
    56.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
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
          :name => "Debian",
          :release => "6.0",
          :version => nil,
          :kernel => "2.6.32"
        })
        storage_devices [
          {:interface => 'IDE', :size => 80.GB, :driver => "amd74xx"}
        ]
        network_adapters [{
          :interface => 'Ethernet',
          :rate => 1.G,
          :mac => lookup('capricorne',"#{node_uid}",'network_interfaces','eth0','mac'),
          :vendor => 'Broadcom',
          :model => 'BCM5704',
          :enabled => true,
          :management => false,
          :mountable => true,
          :driver => 'tg3',
          :mounted => false,
        },{
          :interface => 'Ethernet',
          :rate => 1.G,
          :mac => lookup('capricorne',"#{node_uid}",'network_interfaces','eth1','mac'),
          :vendor => 'Broadcom',
          :model => 'BCM5704',
          :enabled => true,
          :management => false,
          :bridged => true,
          :mountable => true,
          :driver => 'tg3',
          :mounted => true,
          :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
          :device => 'eth1',
          :ip => lookup('capricorne',"#{node_uid}",'network_interfaces','eth1','ip'),
          :switch => 'little-ego'
        },{
          :interface => 'Myrinet',
          :rate => 2.G,
          :mac => lookup('capricorne',"#{node_uid}",'network_interfaces','myri0','mac'),
          :vendor => 'Myrinet',
          :version => "M3F-PCIXF-2",
          :enabled => true,
          :management => false,
          :mountable => true,
          :driver => 'mx',
          :mounted => false,
          :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
          :device => 'myri0',
          :ip => lookup('capricorne',"#{node_uid}",'network_interfaces','myri0','ip'),
        }]
      end
    end
  end # cluster capricorne
end
