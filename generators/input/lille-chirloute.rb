site :lille do |site_uid|

  cluster :chirloute do |cluster_uid|
    model "Dell PowerEdge C6100"
    created_at Time.parse("2011-03-25").httpdate
    8.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => "ivt"})
        architecture({
          :smp_size => 2,
          :smt_size => 8,
          :platform_type => "x86_64"
        })
        processor({
          :vendor => "Intel",
          :model => "Intel Xeon",
          :version => "E5620",
          :clock_speed => 2.4.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 12.MiB
        })
        main_memory({
          :ram_size => 8.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => "Debian",
          :release => "6.0",
          :version => nil,
          :kernel => "2.6.32"
        })
        storage_devices [
          {:interface => 'SATA',
            :size => 300.GB,
            :driver => "mptsas",
          :raid => "0"}
        ]
        network_adapters [{
          :interface => 'Ethernet',
          :rate => 1.G,
          :mac => lookup('lille-chirloute', node_uid, 'network_interfaces', 'eth0', 'mac'),
          :vendor => 'Intel',
          :version => '82576EB',
          :enabled => true,
          :management => false,
          :mountable => true,
          :driver => 'igb',
          :mounted => true,
          :device => 'eth0',
          :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr",
          :ip => lookup('lille-chirloute', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :switch => 'gw'
        },{
          :interface => 'Ethernet',
          :rate => 1.G,
          :mac => lookup('lille-chirloute', node_uid, 'network_interfaces', 'eth1', 'mac'),
          :vendor => 'Intel',
          :version => '82576EB',
          :enabled => true,
          :management => false,
          :mountable => true,
          :driver => 'igb',
          :mounted => true,
          :device => 'eth1',
          :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip => lookup('lille-chirloute', node_uid, 'network_interfaces', 'eth1', 'ip'),
          :switch => 'gw',
          :switch_port => lookup('lille-chirloute', node_uid, 'network_interfaces', 'eth1', 'switch_port')
        },{
          :interface => 'Ethernet',
          :rate => 1.G,
          :mac => lookup('lille-chirloute', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :vendor => 'Inventec',
          :version => 1.14,
          :enabled => true,
          :management => true,
          :mountable => false,
          :network_address => "#{node_uid}-ipmi.#{site_uid}.grid5000.fr",
          :ip => lookup('lille-chirloute', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :switch => 'gw'
        }]
      end
    end
  end # cluster chirloute

end
