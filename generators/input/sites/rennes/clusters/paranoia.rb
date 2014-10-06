site :rennes do |site_uid|

  cluster :paranoia do |cluster_uid|
    model "Dell PowerEdge C6220 II"
    created_at Time.parse("2014-02-21").httpdate
    kavlan true
    production true

    8.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
         :core_flops => 0,
         :node_flops => 0
        })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('paranoia_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('paranoia_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('paranoia_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('paranoia_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('paranoia_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('paranoia_generated', node_uid, 'processor', 'model'),
          :version            => lookup('paranoia_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('paranoia_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('paranoia_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('paranoia_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('paranoia_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('paranoia_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('paranoia_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('paranoia_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('paranoia_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('paranoia_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => "debian",
          :release  => "Wheezy",
          :version  => "7",
          :kernel   => "3.2.0-4-amd64"
        })

        storage_devices [{
          :interface => 'SATA',
          :driver    => "ahci",
          :device    => lookup('paranoia_generated', node_uid, 'block_devices' ,'sda',  'device'),
          :size      => lookup('paranoia_generated', node_uid, 'block_devices' ,'sda',  'size'),
          :model     => lookup('paranoia_generated', node_uid, 'block_devices' ,'sda',  'model'),
          :rev       => lookup('paranoia_generated', node_uid, 'block_devices', 'sda', 'rev'),
          :storage   => 'HDD'
        },
        {
          :interface => 'SATA',
          :driver    => "ahci",
          :device    => lookup('paranoia_generated', node_uid, 'block_devices' ,'sdb',  'device'),
          :size      => lookup('paranoia_generated', node_uid, 'block_devices' ,'sdb',  'size'),
          :model     => lookup('paranoia_generated', node_uid, 'block_devices' ,'sdb',  'model'),
          :rev       => lookup('paranoia_generated', node_uid, 'block_devices', 'sdb', 'rev'),
          :storage   => 'HDD'
        },
        {
          :interface => 'SATA',
          :driver    => "ahci",
          :device    => lookup('paranoia_generated', node_uid, 'block_devices' ,'sdc',  'device'),
          :size      => lookup('paranoia_generated', node_uid, 'block_devices' ,'sdc',  'size'),
          :model     => lookup('paranoia_generated', node_uid, 'block_devices' ,'sdc',  'model'),
          :rev       => lookup('paranoia_generated', node_uid, 'block_devices', 'sdc', 'rev'),
          :storage   => 'HDD'
        },
        {
          :interface => 'SATA',
          :driver    => "ahci",
          :device    => lookup('paranoia_generated', node_uid, 'block_devices' ,'sdd',  'device'),
          :size      => lookup('paranoia_generated', node_uid, 'block_devices' ,'sdd',  'size'),
          :model     => lookup('paranoia_generated', node_uid, 'block_devices' ,'sdd',  'model'),
          :rev       => lookup('paranoia_generated', node_uid, 'block_devices', 'sdd', 'rev'),
          :storage   => 'HDD'
        },
        {
          :interface => 'SATA',
          :driver    => "ahci",
          :device    => lookup('paranoia_generated', node_uid, 'block_devices' ,'sde',  'device'),
          :size      => lookup('paranoia_generated', node_uid, 'block_devices' ,'sde',  'size'),
          :model     => lookup('paranoia_generated', node_uid, 'block_devices' ,'sde',  'model'),
          :rev       => lookup('paranoia_generated', node_uid, 'block_devices', 'sde', 'rev'),
          :storage   => 'HDD'
        }]

        network_adapters [        {
          :interface        => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :rate             => 10.G,
          :device           => "eth0",
          :enabled          => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :vendor           => "Intel",
          :version          => '82599EB 10-Gigabit SFI/SFP+ Network Connection',
          :driver           => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :mac              => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth0', 'mac'),
          :switch_port      => net_port_lookup('rennes', 'paranoia', node_uid, 'eth0'),
          :switch           => net_switch_lookup('rennes', 'paranoia', node_uid, 'eth0')
        },
        {
          :interface        => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 10.G,
          :rate             => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth1', 'rate'),
          :enabled          => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor           => "Intel",
          :version          => '82599EB 10-Gigabit SFI/SFP+ Network Connection',
          :driver           => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth2', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth2', 'enabled'),
          :management       => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth2', 'management'),
          :mountable        => true,
          :mounted          => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth2', 'mounted'),
          :bridged          => false,
          :device           => "eth2",
          :vendor           => "Intel",
          :version          => "Intel Corporation",
          :driver           => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth2', 'driver'),
          :mac              => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth2', 'mac'),
          :switch_port      => net_port_lookup('rennes', 'paranoia', node_uid, 'eth2'),
          :switch           => net_switch_lookup('rennes', 'paranoia', node_uid, 'eth2')
        },
        {
          :interface        => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth3', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth3', 'enabled'),
          :management       => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth3', 'management'),
          :mountable        => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth3', 'mountable'),
          :mounted          => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth3', 'mounted'),
          :bridged          => false,
          :device           => "eth3",
          :vendor           => "Intel",
          :version          => "Intel Corporation",
          :driver           => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth3', 'driver'),
          :mac              => lookup('paranoia_generated', node_uid, 'network_interfaces', 'eth3', 'mac')
        },
        {
          :interface            => 'Ethernet',
          :network_address  => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :rate                 => 1.G,
          :network_address      => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip                   => lookup('paranoia_generated', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac                  => lookup('paranoia_generated', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :enabled              => true,
          :mounted              => false,
          :mountable            => false,
          :management           => true,
          :device               => "bmc",
        }]


        chassis({
          :serial       => lookup('paranoia_generated', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('paranoia_generated', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('paranoia_generated', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('paranoia_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('paranoia_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('paranoia_generated', node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu => false
        })

        monitorint({
          :wattmeter => false,
        })

        sensors({
          :power => {
            :available => false,
          }
        })

      end # node

    end # 8.times

  end # cluster

end # site
