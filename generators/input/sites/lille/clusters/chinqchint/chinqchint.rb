site :lille do |site_uid|

  cluster :chinqchint do |cluster_uid|
    model "Altix Xe 310"
    created_at nil
    created_at Time.parse("2007-09-10").httpdate
    kavlan true
    queues ['default', 'admin']

    46.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :core_flops => 8695000000,
        :node_flops => 52250000000
      })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup(node_uid, node_uid, 'supported_job_types', 'virtual'),
          :max_walltime => 0,
          :queues       => ['default', 'admin']
        })

        architecture({
          :smp_size       => lookup(node_uid, node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup(node_uid, node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup(node_uid, node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup(node_uid, node_uid, 'processor', 'vendor'),
          :model              => lookup(node_uid, node_uid, 'processor', 'model'),
          :version            => lookup(node_uid, node_uid, 'processor', 'version'),
          :clock_speed        => lookup(node_uid, node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup(node_uid, node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup(node_uid, node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup(node_uid, node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup(node_uid, node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup(node_uid, node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup(node_uid, node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup(node_uid, node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup(node_uid, node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => "debian",
          :release  => "Jessie",
          :version  => "7",
          :kernel   => "3.16.0-4-amd64"
        })

        storage_devices [{
          :interface  => 'SATA II',
          :size       => lookup(node_uid, node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "ahci",
          :device     => lookup(node_uid, node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup(node_uid, node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup(node_uid, node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup(node_uid, node_uid, 'block_devices', 'sda', 'rev'),
          :storage    => 'HDD'
        }]

        network_adapters [{
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => false,
          :vendor           => 'Intel',
          :version          => '80003ES2LAN',
          :device           => "eth0",
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'driver'),
          :ip               => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'ip'),
          :switch           => "gw-lille",
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => true,
          :device           => "eth1",
          :vendor           => 'Intel',
          :version          => '80003ES2LAN',
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :switch           => net_switch_lookup('lille', 'chinqchint', node_uid, 'eth1'),
          :switch_port      => net_port_lookup('lille', 'chinqchint', node_uid, 'eth1'),
          :ip               => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'ip'),
          :ip6              => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'ip6'),
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface            => lookup(node_uid, node_uid, 'network_interfaces', 'myri0', 'interface'),
          :rate                 => lookup(node_uid, node_uid, 'network_interfaces', 'myri0', 'rate'),
          :network_address      => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
          :ip                   => lookup(node_uid, node_uid, 'network_interfaces', 'myri0', 'ip'),
          :ip6                  => lookup(node_uid, node_uid, 'network_interfaces', 'myri0', 'ip6'),
          :mac                  => lookup(node_uid, node_uid, 'network_interfaces', 'myri0', 'mac'),
          :vendor               => 'Myricom',
          :version              => "10G-PCIE-8A-C",
          :driver               => lookup(node_uid, node_uid, 'network_interfaces', 'myri0', 'driver'),
          :enabled              => lookup(node_uid, node_uid, 'network_interfaces', 'myri0', 'enabled'),
          :management           => lookup(node_uid, node_uid, 'network_interfaces', 'myri0', 'management'),
          :mountable            => lookup(node_uid, node_uid, 'network_interfaces', 'myri0', 'mountable'),
          :mounted              => lookup(node_uid, node_uid, 'network_interfaces', 'myri0', 'mounted'),
          :management           => false,
          :device               => "myri0",
          :switch               => 'switch-myri'
        },
        {
          :interface            => 'Ethernet',
          :rate                 => 100.M,
          :network_address      => "#{node_uid}-ipmi.#{site_uid}.grid5000.fr",
          :ip                   => lookup(node_uid, node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac                  => lookup(node_uid, node_uid, 'network_interfaces', 'bmc', 'mac'),
          :enabled              => true,
          :mounted              => false,
          :mountable            => false,
          :management           => true,
          :device               => "bmc",
        }]

        chassis({
          :serial       => lookup(node_uid, node_uid, 'chassis', 'serial_number'),
          :name         => lookup(node_uid, node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup(node_uid, node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup(node_uid, node_uid, 'bios', 'version'),
          :vendor       => lookup(node_uid, node_uid, 'bios', 'vendor'),
          :release_date => lookup(node_uid, node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu  => false
        })

      end
    end
  end
end
