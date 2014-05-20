site :reims do |site_uid|

  cluster :stremi do |cluster_uid|
    model "HP ProLiant DL165 G7"
    created_at Time.parse("2011-04-18").httpdate
    kavlan true
    production true

    44.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :core_flops => 4931000000,
        :node_flops => 121300000000
      })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('stremi_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('stremi_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('stremi_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('stremi_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('stremi_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('stremi_generated', node_uid, 'processor', 'model'),
          :version            => lookup('stremi_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('stremi_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('stremi_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('stremi_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('stremi_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('stremi_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('stremi_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('stremi_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('stremi_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('stremi_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('stremi_generated', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('stremi_generated', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('stremi_generated', node_uid, 'operating_system', 'kernel')
        })

        storage_devices [{
          :interface  => 'SATA',
          :size       => lookup('stremi_generated', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "ahci",
          :device     => lookup('stremi_generated', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('stremi_generated', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('stremi_generated', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('stremi_generated', node_uid, 'block_devices', 'sda', 'rev')
        }]

        network_adapters [{
          :interface        => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :driver           => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => lookup('stremi_manual', node_uid, 'network_interfaces', 'eth0', 'switch_name'),
          :switch_port      => lookup('stremi_manual', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :driver           => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth2', 'interface'),
          :rate             => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth2', 'rate'),
          :enabled          => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth2', 'enabled'),
          :management       => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth2', 'management'),
          :mountable        => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth2', 'mountable'),
          :mounted          => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth2', 'mounted'),
          :bridged          => false,
          :device           => "eth2",
          :driver           => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth2', 'driver'),
          :mac              => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth2', 'mac')
        },
        {
          :interface        => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth3', 'interface'),
          :rate             => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth3', 'rate'),
          :enabled          => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth3', 'enabled'),
          :management       => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth3', 'management'),
          :mountable        => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth3', 'mountable'),
          :mounted          => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth3', 'mounted'),
          :bridged          => false,
          :device           => "eth3",
          :driver           => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth3', 'driver'),
          :mac              => lookup('stremi_generated', node_uid, 'network_interfaces', 'eth3', 'mac')
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
          :ip               => lookup('stremi_generated', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac              => lookup('stremi_generated', node_uid, 'network_interfaces', 'bmc', 'mac'),
        }]

        chassis({
          :serial       => lookup('stremi_generated', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('stremi_generated', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('stremi_generated', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('stremi_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('stremi_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('stremi_generated', node_uid, 'bios', 'release_date')
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
              :api => { :metric => 'pdu' },
              :pdu => [ {
                :uid  => lookup('stremi_manual', node_uid, 'pdu', 'pdu_name'),
                :port => lookup('stremi_manual', node_uid, 'pdu', 'pdu_position'),
              } ]
            }
          }
        })

      end
    end
  end
end
