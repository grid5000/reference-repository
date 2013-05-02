site :toulouse do |site_uid|

  cluster :pastel do |cluster_uid|
    model "Sun Fire X2200 M2"
    created_at Time.parse("2007-11-29").httpdate
    kavlan true

    140.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :node_flops     => 17.37.G,
        :core_flops     => 4.463.G
      })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('pastel', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('pastel', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('pastel', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('pastel', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('pastel', node_uid, 'processor', 'vendor'),
          :model              => lookup('pastel', node_uid, 'processor', 'model'),
          :version            => lookup('pastel', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('pastel', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('pastel', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('pastel', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('pastel', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('pastel', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('pastel', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('pastel', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('pastel', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('pastel', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('pastel', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('pastel', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('pastel', node_uid, 'operating_system', 'kernel')
        })

        storage_devices [{
          :interface  => 'SATA',
          :size       => lookup('pastel', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "sata_nv",
          :device     => lookup('pastel', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('pastel', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('pastel', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('pastel', node_uid, 'block_devices', 'sda', 'rev')
        }]

        network_adapters [{
          :interface        => lookup('pastel', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('pastel', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('pastel', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('pastel', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('pastel', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('pastel', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :vendor           => "NVIDIA",
          :version          => "MCP55 Pro",
          :device           => "eth0",
          :driver           => lookup('pastel', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('pastel', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('pastel', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => lookup('pastel', node_uid, 'network_interfaces', 'eth0', 'switch_name'),
          :switch_port      => lookup('pastel', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('pastel', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('pastel', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('pastel', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('pastel', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('pastel', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('pastel', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor           => "NVIDIA",
          :version          => "MCP55 Pro",
          :switch           => nil,
          :driver           => lookup('pastel', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :network_address  => "#{node_uid}-eth1.#{site_uid}.grid5000.fr",
          :mac              => lookup('pastel', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        { :interface => 'Ethernet',
          :rate => 1.G,
          :mac => lookup('pastel', node_uid, 'network_interfaces','bmc','mac'),
          :vendor => "Broadcom",
          :version => "BCM5715c",
          :enabled => true,
          :management => true,
          :mountable => false,
          :mounted => false,
          :network_address => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip => lookup('pastel', node_uid,'network_interfaces','bmc','ip'),
          :ip6 => nil,
          :switch => '<unknown>'
        }]

        chassis({
          :serial       => lookup('pastel', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('pastel', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('pastel', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version	=> lookup('pastel', node_uid, 'bios', 'version'),
          :vendor	=> lookup('pastel', node_uid, 'bios', 'vendor'),
          :release_date	=> lookup('pastel', node_uid, 'bios', 'release_date')
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
