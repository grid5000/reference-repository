site :nancy do |site_uid|

  cluster :talc do |cluster_uid|
    model "Carri System CS-5393B"
    created_at Time.parse("2009-04-10").httpdate
    kavlan true

    134.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('talc_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('talc_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('talc_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('talc_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('talc_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('talc_generated', node_uid, 'processor', 'model'),
          :version            => lookup('talc_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('talc_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('talc_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('talc_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('talc_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('talc_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('talc_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('talc_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('talc_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('talc_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('talc_generated', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('talc_generated', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('talc_generated', node_uid, 'operating_system', 'kernel')
        })
        storage_devices [{
          :interface  => 'SATA II',
          :size       => lookup('talc_generated', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "ahci",
          :device     => lookup('talc_generated', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('talc_generated', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('talc_generated', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('talc_generated', node_uid, 'block_devices', 'sda', 'rev')
        }]

        network_adapters [{
          :interface        => lookup('talc_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('talc_generated', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('talc_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('talc_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('talc_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('talc_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :vendor           => "intel",
          :version          => "80003ES2LAN",
          :driver           => lookup('talc_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('talc_generated', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('talc_generated', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :mac              => lookup('talc_generated', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('talc_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('talc_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('talc_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('talc_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('talc_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor           => "intel",
          :version          => "BCM5721",
          :driver           => lookup('talc_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('talc_generated', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface            => 'Ethernet',
          :rate                 => 100.M,
          :network_address      => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip                   => lookup('talc_generated', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac                  => lookup('talc_generated', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :enabled              => true,
          :mounted              => false,
          :mountable            => false,
          :management           => true,
          :device               => "bmc",
          :vendor               => "Tyan",
          :version              => "M3296"
        }]

        chassis({
          :name         => lookup('talc_generated', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('talc_generated', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('talc_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('talc_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('talc_generated', node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu  => false
        })

      end
    end
  end # cluster talc
end # nancy
