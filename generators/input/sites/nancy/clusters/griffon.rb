site :nancy do |site_uid|

  cluster :griffon do |cluster_uid|
    model "Carri System CS-5393B"
    created_at Time.parse("2009-04-10").httpdate
    kavlan true

    92.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :core_flops => 7.963.G,
        :node_flops => 52.5.G
      })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('griffon', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('griffon', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('griffon', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('griffon', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('griffon', node_uid, 'processor', 'vendor'),
          :model              => lookup('griffon', node_uid, 'processor', 'model'),
          :version            => lookup('griffon', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('griffon', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('griffon', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('griffon', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('griffon', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('griffon', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('griffon', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('griffon', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('griffon', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('griffon', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('griffon', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('griffon', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('griffon', node_uid, 'operating_system', 'kernel')
        })
        storage_devices [{
          :interface  => 'SATA II',
          :size       => lookup('griffon', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "ahci",
          :device     => lookup('griffon', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('griffon', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('griffon', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('griffon', node_uid, 'block_devices', 'sda', 'rev')
        }]

        network_adapters [{
          :interface        => lookup('griffon', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('griffon', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('griffon', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('griffon', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('griffon', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('griffon', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :vendor           => "intel",
          :version          => "80003ES2LAN",
          :driver           => lookup('griffon', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('griffon', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('griffon', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => lookup('griffon', node_uid, 'network_interfaces', 'eth0', 'switch_name'),
          :switch_port      => lookup('griffon', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('griffon', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('griffon', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('griffon', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('griffon', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('griffon', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('griffon', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :vendor           => "intel",
          :version          => "BCM5721",
          :driver           => lookup('griffon', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('griffon', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => lookup('griffon', node_uid, 'network_interfaces', 'ib0', 'interface'),
          :rate             => lookup('griffon', node_uid, 'network_interfaces', 'ib0', 'rate'),
          :device           => "ib0",
          :enabled          => lookup('griffon', node_uid, 'network_interfaces', 'ib0', 'enabled'),
          :management       => lookup('griffon', node_uid, 'network_interfaces', 'ib0', 'management'),
          :mountable        => lookup('griffon', node_uid, 'network_interfaces', 'ib0', 'mountable'),
          :mounted          => lookup('griffon', node_uid, 'network_interfaces', 'ib0', 'mounted'),
          :vendor           => 'Mellanox',
          :version          => "MT26418",
          :driver           => lookup('griffon', node_uid, 'network_interfaces', 'ib0', 'driver'),
          :network_address  => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
          :ip               => lookup('griffon', node_uid, 'network_interfaces', 'ib0', 'ip'),
          :ip6               => lookup('griffon', node_uid, 'network_interfaces', 'ib0', 'ip6'),
          :guid             => lookup('griffon', node_uid, 'network_interfaces', 'ib0', 'guid'),
          :switch           => "sgriffonib",
          :ib_switch_card   => lookup('griffon', node_uid, 'network_interfaces', 'ib0', 'line_card'),
          :ib_switch_card_pos => lookup('griffon', node_uid, 'network_interfaces', 'ib0', 'position'),
          :hwid             => lookup('griffon', node_uid, 'network_interfaces', 'ib0', 'hwid')
        },
        {
          :interface        => lookup('griffon', node_uid, 'network_interfaces', 'ib1', 'interface'),
          :rate             => 30.G,
          :device           => "ib1",
          :enabled          => lookup('griffon', node_uid, 'network_interfaces', 'ib1', 'enabled'),
          :management       => lookup('griffon', node_uid, 'network_interfaces', 'ib1', 'management'),
          :mountable        => lookup('griffon', node_uid, 'network_interfaces', 'ib1', 'mountable'),
          :mounted          => lookup('griffon', node_uid, 'network_interfaces', 'ib1', 'mounted'),
          :vendor           => 'Mellanox',
          :version          => "MT26418",
          :driver           => lookup('griffon', node_uid, 'network_interfaces', 'ib1', 'driver'),
          :guid             => lookup('griffon', node_uid, 'network_interfaces', 'ib1', 'guid')
        },
        {
          :interface            => 'Ethernet',
          :rate                 => 100.M,
          :network_address      => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip                   => lookup('griffon', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac                  => lookup('griffon', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :switch               => lookup('griffon', node_uid, 'network_interfaces', 'bmc', 'switch_name'),
          :switch_port          => lookup('griffon', node_uid, 'network_interfaces', 'bmc', 'switch_port'),
          :enabled              => true,
          :mounted              => false,
          :mountable            => false,
          :management           => true,
          :device               => "bmc",
          :vendor               => "Tyan",
          :version              => "M3296"
        }]

        chassis({
          :serial       => lookup('griffon', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('griffon', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('griffon', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('griffon', node_uid, 'bios', 'version'),
          :vendor       => lookup('griffon', node_uid, 'bios', 'vendor'),
          :release_date => lookup('griffon', node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu  => false
        })

        sensors({
          :power => {
            :available => false, # Set to true when pdu resources will be declared
            :via => {
              :pdu => { :uid => lookup('griffon', node_uid, 'pdu', 'pdu_name') }
            }
          }
        })
      end
    end
  end # cluster griffon
end # nancy
