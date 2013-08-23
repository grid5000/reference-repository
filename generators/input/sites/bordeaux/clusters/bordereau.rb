site :bordeaux do |site_uid|

  cluster :bordereau do |cluster_uid|
    model "IBM System x3455"
    created_at Time.parse("2007-10-01 12:00 GMT").httpdate
    misc "IPMI 2.0"
    kavlan false

    93.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :core_flops => 4433200000,
        :node_flops => 16330000000
      })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('bordereau_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('bordereau_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('bordereau_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('bordereau_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('bordereau_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('bordereau_generated', node_uid, 'processor', 'model'),
          :version            => lookup('bordereau_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('bordereau_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('bordereau_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('bordereau_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('bordereau_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('bordereau_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('bordereau_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('bordereau_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('bordereau_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('bordereau_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('bordereau_generated', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('bordereau_generated', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('bordereau_generated', node_uid, 'operating_system', 'kernel')
        })
        storage_devices [{
          :interface  => 'SATA',
          :size       => lookup('bordereau_generated', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "sata_svw",
          :device     => lookup('bordereau_generated', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('bordereau_generated', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('bordereau_generated', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('bordereau_generated', node_uid, 'block_devices', 'sda', 'rev')
        }]
        network_adapters [{
          :interface        => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :vendor           => "Broadcom",
          :version 	    => "BCM5704",
          :driver           => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => "gw-bordeaux",
          :switch_port      => lookup('bordereau_manual', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor           => "Broadcom",
          :version 	    => "BCM5704",
          :network_address  => "#{node_uid}-eth1.#{site_uid}.grid5000.fr",
          :ip               => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth1', 'ip'),
          :ip6              => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :driver           => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('bordereau_generated', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface            => 'Ethernet',
          :rate                 => 100.M,
          :network_address      => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip                   => lookup('bordereau_generated', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac                  => lookup('bordereau_generated', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :enabled              => true,
          :mounted              => false,
          :mountable            => false,
          :management           => true,
          :device               => "bmc"
        }]

        chassis({
          :serial       => lookup('bordereau_generated', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('bordereau_generated', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('bordereau_generated', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('bordereau_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('bordereau_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('bordereau_generated', node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu  => false
        })

        monitoring({
          :wattmeter  => false
        })

      end
    end
  end # cluster bordereau
end
