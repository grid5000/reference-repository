site :grenoble do |site_uid|

  cluster :adonis do |cluster_uid|
    model "Bull R422-E2 dual mobo + Tesla S1070"
    created_at Time.parse("2010-09-02").httpdate
    kavlan false

    10.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :core_flops => 7139000000,
        :node_flops => 55510000000
      })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('adonis', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('adonis', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('adonis', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('adonis', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('adonis', node_uid, 'processor', 'vendor'),
          :model              => lookup('adonis', node_uid, 'processor', 'model'),
          :version            => lookup('adonis', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('adonis', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('adonis', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('adonis', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('adonis', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('adonis', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('adonis', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('adonis', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('adonis', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('adonis', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('adonis', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('adonis', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('adonis', node_uid, 'operating_system', 'kernel')
        })

        storage_devices [{
          :interface  => 'SATA',
          :size       => lookup('adonis', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "ahci",
          :device     => lookup('adonis', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('adonis', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('adonis', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('adonis', node_uid, 'block_devices', 'sda', 'rev')
        }]

        network_adapters [{
          :interface        => lookup('adonis', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('adonis', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('adonis', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('adonis', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('adonis', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('adonis', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :vendor           => 'Intel',
          :version          => "Device 10c9 (rev 01)",
          :driver           => lookup('adonis', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('adonis', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('adonis', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => "gw-grenoble",
          :switch_port      => lookup('adonis', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('adonis', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('adonis', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('adonis', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('adonis', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('adonis', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('adonis', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor           => 'Intel',
          :version          => "Device 10c9 (rev 01)",
          :driver           => lookup('adonis', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('adonis', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => lookup('adonis', node_uid, 'network_interfaces', 'ib0', 'interface'),
          :rate             => lookup('adonis', node_uid, 'network_interfaces', 'ib0', 'rate'),
          :device           => "ib0",
          :enabled          => lookup('adonis', node_uid, 'network_interfaces', 'ib0', 'enabled'),
          :management       => lookup('adonis', node_uid, 'network_interfaces', 'ib0', 'management'),
          :mountable        => lookup('adonis', node_uid, 'network_interfaces', 'ib0', 'mountable'),
          :mounted          => lookup('adonis', node_uid, 'network_interfaces', 'ib0', 'mounted'),
          :vendor           => 'Mellanox',
          :version          => lookup('adonis', node_uid, 'network_interfaces', 'ib0', 'version'),
          :driver           => lookup('adonis', node_uid, 'network_interfaces', 'ib0', 'driver'),
          :network_address  => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
          :ip               => lookup('adonis', node_uid, 'network_interfaces', 'ib0', 'ip'),
          :ip6              => lookup('adonis', node_uid, 'network_interfaces', 'ib0', 'ip6'),
          :guid             => lookup('adonis', node_uid, 'network_interfaces', 'ib0', 'guid')
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
          :ip               => lookup('adonis', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :vendor           => 'Super Micro Computer Inc.',
          :version          => "1.15",
          :mac              => lookup('adonis', node_uid, 'network_interfaces', 'bmc', 'mac')
        }]

        chassis({
          :serial       => lookup('adonis', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('adonis', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('adonis', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('adonis', node_uid, 'bios', 'version'),
          :vendor       => lookup('adonis', node_uid, 'bios', 'vendor'),
          :release_date => lookup('adonis', node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu         => true,
          :gpu_count   =>  lookup('adonis', node_uid, 'gpu', 'gpu_count'),
          :gpu_model   =>  lookup('adonis', node_uid, 'gpu', 'gpu_model'),
        })

        sensors({
          :power => {
            :available => true,
            :via => {
              :pdu  => [
                [ { :measure 	=>  lookup('adonis', node_uid, 'sensors', 'measure1'), 
                    :uid			=>  lookup('adonis', node_uid, 'sensors', 'pdu')},
                  { :measure	=> 	lookup('adonis', node_uid, 'sensors', 'measure2'), 
                    :uid			=>  lookup('adonis', node_uid, 'sensors', 'pdu')}
                ],
                [ { :measure	=> 	"global", 
                    :uid			=>	lookup('adonis', node_uid, 'sensors', 'block')}
                ]
              ]
            }
          }
        })

      end
    end
  end
end
