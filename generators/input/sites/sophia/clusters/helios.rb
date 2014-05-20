site :sophia do |site_uid|

  cluster :helios do |cluster_uid|
    model "Sun Fire X4100"
    created_at Time.parse("2006-06-02").httpdate
    kavlan true
    production true

    56.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
          :core_flops => 3686000000,
          :node_flops => 14260000000
        })

        architecture({
          :smp_size => 2,
          :smt_size => 4,
          :platform_type => "x86_64"
        })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('helios_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('helios_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('helios_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('helios_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('helios_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('helios_generated', node_uid, 'processor', 'model'),
          :version            => lookup('helios_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('helios_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('helios_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('helios_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('helios_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('helios_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('helios_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('helios_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('helios_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('helios_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('helios_generated', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('helios_generated', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('helios_generated', node_uid, 'operating_system', 'kernel')
        })

        storage_devices [{
          :interface  => 'SAS',
          :size       => lookup('helios_generated', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "mptsas",
          :device     => lookup('helios_generated', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('helios_generated', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('helios_generated', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('helios_generated', node_uid, 'block_devices', 'sda', 'rev')
        }]

        network_adapters [{
          :interface        => lookup('helios_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('helios_generated', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('helios_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('helios_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('helios_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('helios_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :vendor           => 'Intel',
          :version          => "82546EB",
          :driver           => lookup('helios_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('helios_generated', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('helios_generated', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => lookup('helios_manual', node_uid, 'network_interfaces', 'eth0', 'switch_name'),
          :switch_port      => lookup('helios_manual', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('helios_generated', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('helios_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('helios_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('helios_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('helios_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('helios_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor           => 'Intel',
          :version          => "82546EB",
          :driver           => lookup('helios_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('helios_generated', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => lookup('helios_generated', node_uid, 'network_interfaces', 'eth2', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('helios_generated', node_uid, 'network_interfaces', 'eth2', 'enabled'),
          :management       => lookup('helios_generated', node_uid, 'network_interfaces', 'eth2', 'management'),
          :mountable        => lookup('helios_generated', node_uid, 'network_interfaces', 'eth2', 'mountable'),
          :mounted          => lookup('helios_generated', node_uid, 'network_interfaces', 'eth2', 'mounted'),
          :bridged          => false,
          :device           => "eth2",
          :vendor           => 'Intel',
          :version          => "82546EB",
          :driver           => lookup('helios_generated', node_uid, 'network_interfaces', 'eth2', 'driver'),
          :mac              => lookup('helios_generated', node_uid, 'network_interfaces', 'eth2', 'mac')
        },
        {
          :interface        => lookup('helios_generated', node_uid, 'network_interfaces', 'eth3', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('helios_generated', node_uid, 'network_interfaces', 'eth3', 'enabled'),
          :management       => lookup('helios_generated', node_uid, 'network_interfaces', 'eth3', 'management'),
          :mountable        => lookup('helios_generated', node_uid, 'network_interfaces', 'eth3', 'mountable'),
          :mounted          => lookup('helios_generated', node_uid, 'network_interfaces', 'eth3', 'mounted'),
          :bridged          => false,
          :device           => "eth3",
          :vendor           => 'Intel',
          :version          => "82546EB",
          :driver           => lookup('helios_generated', node_uid, 'network_interfaces', 'eth3', 'driver'),
          :mac              => lookup('helios_generated', node_uid, 'network_interfaces', 'eth3', 'mac')
        },
        {
          :interface            => lookup('helios_generated', node_uid, 'network_interfaces', 'myri0', 'interface'),
          :rate                 => lookup('helios_generated', node_uid, 'network_interfaces', 'myri0', 'rate'),
          :network_address      => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
          :ip                   => lookup('helios_generated', node_uid, 'network_interfaces', 'myri0', 'ip'),
          :ip6                  => lookup('helios_generated', node_uid, 'network_interfaces', 'myri0', 'ip6'),
          :mac                  => lookup('helios_generated', node_uid, 'network_interfaces', 'myri0', 'mac'),
          :vendor               => 'Myricom',
          :version              => "M3F-PCIXF-2",
          :driver               => lookup('helios_generated', node_uid, 'network_interfaces', 'myri0', 'driver'),
          :enabled              => lookup('helios_generated', node_uid, 'network_interfaces', 'myri0', 'enabled'),
          :management           => lookup('helios_generated', node_uid, 'network_interfaces', 'myri0', 'management'),
          :mountable            => lookup('helios_generated', node_uid, 'network_interfaces', 'myri0', 'mountable'),
          :mounted              => lookup('helios_generated', node_uid, 'network_interfaces', 'myri0', 'mounted'),
          :management           => false,
          :device               => "myri0",
          :switch               => 'sw-myrinet'
        },
        {
          :interface => 'Ethernet',
          :rate => 100.M,
          :network_address  => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip => lookup('helios_generated', node_uid, 'network_interfaces','bmc', 'ip'),
          :mac => lookup('helios_generated', node_uid, 'network_interfaces','bmc', 'mac'),
          :enabled  => true,
          :mounted => false,
          :mountable => false,
          :management => true,
          :device => "bmc"
        }]

        chassis({
          :serial       => lookup('helios_generated', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('helios_generated', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('helios_generated', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('helios_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('helios_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('helios_generated', node_uid, 'bios', 'release_date')
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
