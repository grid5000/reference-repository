site :bordeaux do |site_uid|

  cluster :bordeplage do |cluster_uid|
    model "Dell PowerEdge 1855"
    kavlan false
    created_at nil

    51.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :core_flops => 4820000000,
        :node_flops => 9000000000
      })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('bordeplage', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('bordeplage', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('bordeplage', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('bordeplage', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('bordeplage', node_uid, 'processor', 'vendor'),
          :model              => lookup('bordeplage', node_uid, 'processor', 'model'),
          :version            => lookup('bordeplage', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('bordeplage', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('bordeplage', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('bordeplage', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('bordeplage', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('bordeplage', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('bordeplage', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('bordeplage', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('bordeplage', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('bordeplage', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('bordeplage', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('bordeplage', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('bordeplage', node_uid, 'operating_system', 'kernel')
        })

        storage_devices [{
          :interface  => 'SCSI',
          :size       => lookup('bordeplage', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "mptspi",
          :device     => lookup('bordeplage', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('bordeplage', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('bordeplage', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('bordeplage', node_uid, 'block_devices', 'sda', 'rev')
        }]

        network_adapters [{
          :interface        => lookup('bordeplage', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('bordeplage', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('bordeplage', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('bordeplage', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('bordeplage', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('bordeplage', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :vendor 	    => "Intel",
          :version 	    => "82546GB Gigabit Ethernet Controller",
          :driver           => lookup('bordeplage', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('bordeplage', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('bordeplage', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => "sbordeplage",
          :switch_port      => lookup('bordeplage', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('bordeplage', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('bordeplage', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('bordeplage', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('bordeplage', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('bordeplage', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('bordeplage', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor 	    => "Intel",
          :version 	    => "82546GB Gigabit Ethernet Controller",
          :network_address  => "#{node_uid}-eth1.#{site_uid}.grid5000.fr",
          :ip               => lookup('bordeplage', node_uid, 'network_interfaces', 'eth1', 'ip'),
          :driver           => lookup('bordeplage', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('bordeplage', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => lookup('bordeplage', node_uid, 'network_interfaces', 'ib0', 'interface'),
          :rate             => lookup('bordeplage', node_uid, 'network_interfaces', 'ib0', 'rate'),
          :device           => "ib0",
          :enabled          => lookup('bordeplage', node_uid, 'network_interfaces', 'ib0', 'enabled'),
          :management       => lookup('bordeplage', node_uid, 'network_interfaces', 'ib0', 'management'),
          :mountable        => lookup('bordeplage', node_uid, 'network_interfaces', 'ib0', 'mountable'),
          :mounted          => lookup('bordeplage', node_uid, 'network_interfaces', 'ib0', 'mounted'),
          :vendor           => 'Mellanox',
          :version          => lookup('bordeplage', node_uid, 'network_interfaces', 'ib0', 'version'),
          :driver           => lookup('bordeplage', node_uid, 'network_interfaces', 'ib0', 'driver'),
          :network_address  => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
          :ip               => lookup('bordeplage', node_uid, 'network_interfaces', 'ib0', 'ip'),
          :guid             => lookup('bordeplage', node_uid, 'network_interfaces', 'ib0', 'guid')
        },
        {
          :interface        => lookup('bordeplage', node_uid, 'network_interfaces', 'ib1', 'interface'),
          :rate             => 10.G,
          :device           => "ib1",
          :enabled          => lookup('bordeplage', node_uid, 'network_interfaces', 'ib1', 'enabled'),
          :management       => lookup('bordeplage', node_uid, 'network_interfaces', 'ib1', 'management'),
          :mountable        => lookup('bordeplage', node_uid, 'network_interfaces', 'ib1', 'mountable'),
          :mounted          => lookup('bordeplage', node_uid, 'network_interfaces', 'ib1', 'mounted'),
          :vendor           => 'Mellanox',
          :version          => lookup('bordeplage', node_uid, 'network_interfaces', 'ib1', 'version'),
          :driver           => lookup('bordeplage', node_uid, 'network_interfaces', 'ib1', 'driver'),
          :guid             => lookup('bordeplage', node_uid, 'network_interfaces', 'ib1', 'guid')
        },
        {
          :interface            => 'Ethernet',
          :rate                 => 100.M,
          :network_address      => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip                   => lookup('bordeplage', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac                  => lookup('bordeplage', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :enabled              => true,
          :mounted              => false,
          :mountable            => false,
          :management           => true,
          :device               => "bmc"
        }]

        chassis({
          :serial       => lookup('bordeplage', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('bordeplage', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('bordeplage', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('bordeplage', node_uid, 'bios', 'version'),
          :vendor       => lookup('bordeplage', node_uid, 'bios', 'vendor'),
          :release_date => lookup('bordeplage', node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu  => false
        })

        monitoring({
          :wattmeter  => false
        })
      end
    end
  end # cluster bordeplage
  #misc "Motherboard Bios version: A05 ;IPMI version 1.5: Firware revision 1.6"
end
