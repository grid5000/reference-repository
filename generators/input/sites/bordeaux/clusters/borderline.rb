site :bordeaux do |site_uid|

  cluster :borderline do |cluster_uid|
    model "IBM System x3755"
    created_at Time.parse("2007-10-01 12:00 GMT").httpdate
    misc "IPMI 2.0"
    kavlan false

    10.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :core_flops => 4424000000,
        :node_flops => 34880000000
      })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('borderline_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('borderline_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('borderline_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('borderline_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('borderline_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('borderline_generated', node_uid, 'processor', 'model'),
          :version            => lookup('borderline_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('borderline_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('borderline_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('borderline_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('borderline_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('borderline_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('borderline_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('borderline_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('borderline_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('borderline_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('borderline_generated', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('borderline_generated', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('borderline_generated', node_uid, 'operating_system', 'kernel')
        })
        storage_devices [{
          :interface  => 'SAS',
          :size       => lookup('borderline_generated', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "aacraid",
          :device     => lookup('borderline_generated', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('borderline_generated', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('borderline_generated', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('borderline_generated', node_uid, 'block_devices', 'sda', 'rev')
        }]

        network_adapters [{
          :interface        => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :vendor           => "Broadcom",
          :version 	    => "NetXtreme II BCM5708",
          :driver           => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => "sborderline",
          :switch_port      => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor 	    => "Broadcom",
          :version 	    => "NetXtreme II BCM5708",
          :network_address  => "#{node_uid}-eth1.#{site_uid}.grid5000.fr",
          :ip               => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth1', 'ip'),
          :driver           => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('borderline_generated', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => lookup('borderline_generated', node_uid, 'network_interfaces', 'ib0', 'interface'),
          :rate             => lookup('borderline_generated', node_uid, 'network_interfaces', 'ib0', 'rate'),
          :device           => "ib0",
          :enabled          => lookup('borderline_generated', node_uid, 'network_interfaces', 'ib0', 'enabled'),
          :management       => lookup('borderline_generated', node_uid, 'network_interfaces', 'ib0', 'management'),
          :mountable        => lookup('borderline_generated', node_uid, 'network_interfaces', 'ib0', 'mountable'),
          :mounted          => lookup('borderline_generated', node_uid, 'network_interfaces', 'ib0', 'mounted'),
          :vendor           => 'Mellanox',
          :version 	    => lookup('borderline_generated', node_uid, 'network_interfaces', 'ib0', 'version'),
          :driver           => lookup('borderline_generated', node_uid, 'network_interfaces', 'ib0', 'driver'),
          :network_address  => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
          :ip               => lookup('borderline_generated', node_uid, 'network_interfaces', 'ib0', 'ip'),
          :guid             => lookup('borderline_generated', node_uid, 'network_interfaces', 'ib0', 'guid')
        },
        {
          :interface        => lookup('borderline_generated', node_uid, 'network_interfaces', 'ib1', 'interface'),
          :rate             => 10.G,
          :device           => "ib1",
          :enabled          => lookup('borderline_generated', node_uid, 'network_interfaces', 'ib1', 'enabled'),
          :management       => lookup('borderline_generated', node_uid, 'network_interfaces', 'ib1', 'management'),
          :mountable        => lookup('borderline_generated', node_uid, 'network_interfaces', 'ib1', 'mountable'),
          :mounted          => lookup('borderline_generated', node_uid, 'network_interfaces', 'ib1', 'mounted'),
          :vendor           => 'Mellanox',
          :version 	    => lookup('borderline_generated', node_uid, 'network_interfaces', 'ib1', 'version'),
          :driver           => lookup('borderline_generated', node_uid, 'network_interfaces', 'ib1', 'driver'),
          :guid             => lookup('borderline_generated', node_uid, 'network_interfaces', 'ib1', 'guid')
        },
        {
          :interface 		=> 'Myrinet',
          :rate 		=> 10.G,
          :network_address 	=> "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
          :ip 			=> lookup('borderline_generated', node_uid, 'network_interfaces', 'myri0', 'ip'),
          :ip6 			=> lookup('borderline_generated', node_uid, 'network_interfaces', 'myri0', 'ip6'),
          :mac 			=> lookup('borderline_generated', node_uid, 'network_interfaces', 'myri0', 'mac'),
          :vendor 		=> 'Myrinet',
          :version 		=> "10G-PCIE-8A-C",
          :driver               => lookup('borderline_generated', node_uid, 'network_interfaces', 'myri0', 'driver'),
          :enabled              => lookup('borderline_generated', node_uid, 'network_interfaces', 'myri0', 'enabled'),
          :management           => lookup('borderline_generated', node_uid, 'network_interfaces', 'myri0', 'management'),
          :mountable            => lookup('borderline_generated', node_uid, 'network_interfaces', 'myri0', 'mountable'),
          :mounted              => lookup('borderline_generated', node_uid, 'network_interfaces', 'myri0', 'mounted'),
          :management 		=> false,
          :device 		=> "myri0"
        },
        {
          :interface 		=> 'Ethernet',
          :rate 		=> 100.M,
          :network_address 	=> "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip 			=> lookup('borderline_generated', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac 			=> lookup('borderline_generated', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :enabled 		=> true,
          :mounted 		=> false,
          :mountable 		=> false,
          :management 		=> true,
          :device 		=> "bmc"
        }]

        chassis({
          :serial       => lookup('borderline_generated', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('borderline_generated', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('borderline_generated', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('borderline_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('borderline_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('borderline_generated', node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu  => false
        })


        monitoring({
          :wattmeter  => false
        })
      end
    end
  end # cluster borderline
end
