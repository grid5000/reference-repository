site :sophia do |site_uid|

  cluster :sol do |cluster_uid|
    model "Sun Fire X2200 M2"
    created_at Time.parse("2007-02-23").httpdate
    kavlan true

    50.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
          :core_flops => 4337000000,
          :node_flops => 16800000000
        })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('sol', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('sol', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('sol', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('sol', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('sol', node_uid, 'processor', 'vendor'),
          :model              => lookup('sol', node_uid, 'processor', 'model'),
          :version            => lookup('sol', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('sol', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('sol', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('sol', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('sol', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('sol', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('sol', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('sol', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('sol', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('sol', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('sol', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('sol', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('sol', node_uid, 'operating_system', 'kernel')
        })

        storage_devices [{
          :interface  => 'SATA',
          :size       => lookup('sol', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "sata_nv",
          :device     => lookup('sol', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('sol', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('sol', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('sol', node_uid, 'block_devices', 'sda', 'rev')
        }]

        network_adapters [{
          :interface        => lookup('sol', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('sol', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('sol', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('sol', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('sol', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('sol', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :vendor           => 'nVidia',
          :version          => "MCP55 Pro",
          :driver           => lookup('sol', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('sol', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('sol', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => "gw-sophia",
          :switch_port      => lookup('sol', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('sol', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('sol', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('sol', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('sol', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('sol', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('sol', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor           => 'nVidia',
          :version          => "MCP55 Pro",
          :driver           => lookup('sol', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :ip               => lookup('sol', node_uid, 'network_interfaces', 'eth1', 'ip'),
          :mac              => lookup('sol', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface => 'Ethernet',
          :rate => 100.M,
          :network_address  => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip => lookup('sol', node_uid, 'network_interfaces','bmc', 'ip'),
          :mac => lookup('sol', node_uid, 'network_interfaces','bmc', 'mac'),
          :enabled  => true,
          :mounted => false,
          :mountable => false,
          :management => true,
          :device => "bmc"
        },
        {
          :interface            => lookup('sol', node_uid, 'network_interfaces', 'myri0', 'interface'),
          :rate                 => lookup('sol', node_uid, 'network_interfaces', 'myri0', 'rate'),
          :network_address      => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
          :ip                   => lookup('sol', node_uid, 'network_interfaces', 'myri0', 'ip'),
          :ip6                  => lookup('sol', node_uid, 'network_interfaces', 'myri0', 'ip6'),
          :mac                  => lookup('sol', node_uid, 'network_interfaces', 'myri0', 'mac'),
          :vendor               => 'Myricom',
          :version              => "M3F-PCIXF-2",
          :driver               => lookup('sol', node_uid, 'network_interfaces', 'myri0', 'driver'),
          :enabled              => lookup('sol', node_uid, 'network_interfaces', 'myri0', 'enabled'),
          :management           => lookup('sol', node_uid, 'network_interfaces', 'myri0', 'management'),
          :mountable            => lookup('sol', node_uid, 'network_interfaces', 'myri0', 'mountable'),
          :mounted              => lookup('sol', node_uid, 'network_interfaces', 'myri0', 'mounted'),
          :management           => false,
          :device               => "myri0",
          :switch               => 'sw-myrinet'
        }]

        chassis({
          :serial       => lookup('sol', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('sol', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('sol', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('sol', node_uid, 'bios', 'version'),
          :vendor       => lookup('sol', node_uid, 'bios', 'vendor'),
          :release_date => lookup('sol', node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu  => false
        })

        monitoring({
          :wattmeter  => false
        })
      end
    end
  end

end
