site :lille do |site_uid|

  cluster :chinqchint do |cluster_uid|
    model "Altix Xe 310"
    created_at nil
    kavlan true
    production true

    46.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :core_flops => 8695000000,
        :node_flops => 52250000000
      })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('chinqchint_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('chinqchint_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('chinqchint_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('chinqchint_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('chinqchint_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('chinqchint_generated', node_uid, 'processor', 'model'),
          :version            => lookup('chinqchint_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('chinqchint_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('chinqchint_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('chinqchint_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('chinqchint_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('chinqchint_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('chinqchint_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('chinqchint_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('chinqchint_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('chinqchint_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => "debian",
          :release  => "Wheezy",
          :version  => "7",
          :kernel   => "3.2.0-4-amd64"
        })

        storage_devices [{
          :interface  => 'SATA II',
          :size       => lookup('chinqchint_generated', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "ahci",
          :device     => lookup('chinqchint_generated', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('chinqchint_generated', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('chinqchint_generated', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('chinqchint_generated', node_uid, 'block_devices', 'sda', 'rev'),
          :storage    => 'HDD'
        }]

        network_adapters [{
          :interface        => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => false,
          :vendor           => 'Intel',
          :version          => '80003ES2LAN',
          :device           => "eth0",
          :driver           => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :ip               => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :switch           => "gw-lille",
          :mac              => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => true,
          :device           => "eth1",
          :vendor           => 'Intel',
          :version          => '80003ES2LAN',
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :switch           => net_switch_lookup('lille', 'chinqchint', node_uid, 'eth1'),
          :switch_port      => net_port_lookup('lille', 'chinqchint', node_uid, 'eth1'),
          :ip               => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'eth1', 'ip'),
          :ip6              => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'eth1', 'ip6'),
          :driver           => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface            => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'myri0', 'interface'),
          :rate                 => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'myri0', 'rate'),
          :network_address      => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
          :ip                   => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'myri0', 'ip'),
          :ip6                  => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'myri0', 'ip6'),
          :mac                  => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'myri0', 'mac'),
          :vendor               => 'Myricom',
          :version              => "10G-PCIE-8A-C",
          :driver               => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'myri0', 'driver'),
          :enabled              => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'myri0', 'enabled'),
          :management           => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'myri0', 'management'),
          :mountable            => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'myri0', 'mountable'),
          :mounted              => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'myri0', 'mounted'),
          :management           => false,
          :device               => "myri0",
          :switch               => 'switch-myri'
        },
        {
          :interface            => 'Ethernet',
          :rate                 => 100.M,
          :network_address      => "#{node_uid}-ipmi.#{site_uid}.grid5000.fr",
          :ip                   => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac                  => lookup('chinqchint_generated', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :enabled              => true,
          :mounted              => false,
          :mountable            => false,
          :management           => true,
          :device               => "bmc",
        }]

        chassis({
          :serial       => lookup('chinqchint_generated', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('chinqchint_generated', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('chinqchint_generated', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('chinqchint_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('chinqchint_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('chinqchint_generated', node_uid, 'bios', 'release_date')
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
