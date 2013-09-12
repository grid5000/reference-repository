site :luxembourg do |site_uid|

  cluster :petitprince do |cluster_uid|
    model "PowerEdge M620"
    created_at Time.parse("2013-09-10").httpdate
    kavlan false

    16.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :node_flops     => 192.G,
        :core_flops     => 16.G
        })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('petitprince_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('petitprince_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('petitprince_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('petitprince_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('petitprince_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('petitprince_generated', node_uid, 'processor', 'model'),
          :version            => lookup('petitprince_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('petitprince_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('petitprince_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('petitprince_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('petitprince_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('petitprince_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('petitprince_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('petitprince_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('petitprince_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('petitprince_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('petitprince_generated', node_uid, 'operating_system', 'name'),
          :release  => "Wheezy",
          :version  => lookup('petitprince_generated', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('petitprince_generated', node_uid, 'operating_system', 'kernel')
        })

        storage_devices [{
          :interface  => 'SATA',
          :size       => lookup('petitprince_generated', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "ahci",
          :device     => lookup('petitprince_generated', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('petitprince_generated', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('petitprince_generated', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('petitprince_generated', node_uid, 'block_devices', 'sda', 'rev')
        }]

        network_adapters [{
          :interface        => lookup('petitprince_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('petitprince_generated', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('petitprince_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('petitprince_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('petitprince_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('petitprince_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged 	        => true,
          :device           => "eth0",
          :driver           => lookup('petitprince_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('petitprince_generated', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('petitprince_generated', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => "mxl1",
          :switch_port      => lookup('petitprince_manual', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('petitprince_generated', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('petitprince_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 10.G,
          :enabled          => lookup('petitprince_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('petitprince_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('petitprince_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('petitprince_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged 	        => false,
          :device           => "eth1",
          :driver           => lookup('petitprince_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('petitprince_generated', node_uid, 'network_interfaces', 'eth1', 'mac'),
          :switch           => "mxl2",
          :switch_port      => lookup('petitprince_manual', node_uid, 'network_interfaces', 'eth1', 'switch_port'),
        },
        {
          :interface        => 'Ethernet',
          :rate             => 1.G,
          :enabled          => true,
          :management       => true,
          :mountable        => false,
          :mounted          => false,
          :device           => "bmc",
          :network_address  => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip               => lookup('petitprince_generated', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :switch           => "gw-luxembourg",
          :switch_port      => lookup('petitprince_manual', node_uid, 'network_interfaces', 'bmc', 'switch_port'),
          :mac              => lookup('petitprince_generated', node_uid, 'network_interfaces', 'bmc', 'mac'),
        }]

        chassis({
          :serial       => lookup('petitprince_manual', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('petitprince_manual', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('petitprince_manual', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('petitprince_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('petitprince_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('petitprince_generated', node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu  => false
        })

        monitoring({
          :wattmeter  => false
        })

        addressing_plan({
          :kavlan => "10.40.0.0/14",
          :virt   => "10.172.0.0/14"
        })

      end
    end
  end
end
