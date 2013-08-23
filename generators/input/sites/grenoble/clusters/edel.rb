site :grenoble do |site_uid|

  cluster :edel do |cluster_uid|
    model "Bull bullx B500 compute blades"
    created_at Time.parse("2008-10-03").httpdate
    kavlan true

    72.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :core_flops => 71394000000,
        :node_flops => 55450000000
      })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('edel_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('edel_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('edel_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('edel_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('edel_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('edel_generated', node_uid, 'processor', 'model'),
          :version            => lookup('edel_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('edel_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('edel_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('edel_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('edel_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('edel_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('edel_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('edel_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('edel_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('edel_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('edel_generated', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('edel_generated', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('edel_generated', node_uid, 'operating_system', 'kernel')
        })

        storage_devices [{
          :interface  => 'SATA',
          :size       => lookup('edel_generated', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "ahci",
          :device     => lookup('edel_generated', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('edel_generated', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('edel_generated', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('edel_generated', node_uid, 'block_devices', 'sda', 'rev')
        }]

        network_adapters [{
          :interface        => lookup('edel_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('edel_generated', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('edel_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('edel_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('edel_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('edel_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :vendor           => 'Intel',
          :version          => "82576 Gigabit Network Connection",
          :driver           => lookup('edel_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('edel_generated', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('edel_generated', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => lookup('edel_manual', node_uid, 'network_interfaces', 'eth0', 'switch_name'),
          :switch_port      => lookup('edel_manual', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('edel_generated', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('edel_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('edel_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('edel_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('edel_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('edel_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor           => 'Intel',
          :version          => "82576 Gigabit Network Connection",
          :driver           => lookup('edel_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('edel_generated', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => lookup('edel_generated', node_uid, 'network_interfaces', 'ib0', 'interface'),
          :rate             => lookup('edel_generated', node_uid, 'network_interfaces', 'ib0', 'rate'),
          :device           => "ib0",
          :enabled          => lookup('edel_generated', node_uid, 'network_interfaces', 'ib0', 'enabled'),
          :management       => lookup('edel_generated', node_uid, 'network_interfaces', 'ib0', 'management'),
          :mountable        => lookup('edel_generated', node_uid, 'network_interfaces', 'ib0', 'mountable'),
          :mounted          => lookup('edel_generated', node_uid, 'network_interfaces', 'ib0', 'mounted'),
          :vendor           => 'Mellanox',
          :version          => lookup('edel_generated', node_uid, 'network_interfaces', 'ib0', 'version'),
          :driver           => lookup('edel_generated', node_uid, 'network_interfaces', 'ib0', 'driver'),
          :network_address  => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
          :ip               => lookup('edel_generated', node_uid, 'network_interfaces', 'ib0', 'ip'),
          :ip6              => lookup('edel_generated', node_uid, 'network_interfaces', 'ib0', 'ip6'),
          :guid             => lookup('edel_generated', node_uid, 'network_interfaces', 'ib0', 'guid')
        },
        {
          :interface        => lookup('edel_generated', node_uid, 'network_interfaces', 'ib1', 'interface'),
          :rate             => 40.G,
          :rate             => lookup('edel_generated', node_uid, 'network_interfaces', 'ib1', 'rate'),
          :device           => "ib1",
          :enabled          => lookup('edel_generated', node_uid, 'network_interfaces', 'ib1', 'enabled'),
          :management       => lookup('edel_generated', node_uid, 'network_interfaces', 'ib1', 'management'),
          :mountable        => lookup('edel_generated', node_uid, 'network_interfaces', 'ib1', 'mountable'),
          :mounted          => lookup('edel_generated', node_uid, 'network_interfaces', 'ib1', 'mounted'),
          :vendor           => 'Mellanox',
          :version          => lookup('edel_generated', node_uid, 'network_interfaces', 'ib1', 'version'),
          :driver           => lookup('edel_generated', node_uid, 'network_interfaces', 'ib1', 'driver'),
          :guid             => lookup('edel_generated', node_uid, 'network_interfaces', 'ib1', 'guid')
        },
        {
          :interface        => 'Ethernet',
          :rate             => 100.M,
          :enabled          => true,
          :management       => true,
          :mountable        => false,
          :mounted          => false,
          :device           => "bmc",
          :network_address  => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip               => lookup('edel_generated', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :vendor           => "Unknown",
          :version          => "1.7",
          :mac              => lookup('edel_generated', node_uid, 'network_interfaces', 'bmc', 'mac')
        }]

        chassis({
          :serial       => lookup('edel_generated', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('edel_generated', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('edel_generated', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('edel_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('edel_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('edel_generated', node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu  => false
        })

        monitoring({
          :wattmeter  => true
        })

        sensors({
          :power => {
            :available => true,
            :via => {
              :api  => { :metric => "pdu" },
              :ipmi     => { :sensors => { :Power => "Power" } }
            }
          }
        })

      end
    end
  end
end
