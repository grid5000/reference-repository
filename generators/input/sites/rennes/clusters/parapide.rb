site :rennes do |site_uid|

  cluster :parapide do |cluster_uid|
    model "SUN FIRE X2270"
    created_at Time.parse("2010-01-25").httpdate
    kavlan true

    25.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :core_flops => 9170000000,
        :node_flops => 71150000000
      })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('parapide_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('parapide_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('parapide_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('parapide_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('parapide_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('parapide_generated', node_uid, 'processor', 'model'),
          :version            => lookup('parapide_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('parapide_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('parapide_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('parapide_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('parapide_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('parapide_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('parapide_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('parapide_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('parapide_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('parapide_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('parapide_generated', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('parapide_generated', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('parapide_generated', node_uid, 'operating_system', 'kernel')
        })

        storage_devices [{
          :interface  => 'SATA',
          :size       => lookup('parapide_generated', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "ahci",
          :device     => lookup('parapide_generated', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('parapide_generated', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('parapide_generated', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('parapide_generated', node_uid, 'block_devices', 'sda', 'rev')
        }]

        network_adapters [{
          :interface        => lookup('parapide_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('parapide_generated', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('parapide_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('parapide_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('parapide_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('parapide_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :vendor           => "Intel",
          :version          => "82575EB",
          :driver           => lookup('parapide_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('parapide_generated', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('parapide_generated', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => lookup('parapide_manual', node_uid, 'network_interfaces', 'eth0', 'switch_name'),
          :switch_port      => lookup('parapide_manual', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('parapide_generated', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('parapide_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('parapide_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('parapide_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('parapide_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('parapide_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor           => "Intel",
          :version          => "82575EB",
          :driver           => lookup('parapide_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('parapide_generated', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => lookup('parapide_generated', node_uid, 'network_interfaces', 'ib0', 'interface'),
          :rate             => lookup('parapide_generated', node_uid, 'network_interfaces', 'ib0', 'rate'),
          :device           => "ib0",
          :enabled          => lookup('parapide_generated', node_uid, 'network_interfaces', 'ib0', 'enabled'),
          :management       => lookup('parapide_generated', node_uid, 'network_interfaces', 'ib0', 'management'),
          :mountable        => lookup('parapide_generated', node_uid, 'network_interfaces', 'ib0', 'mountable'),
          :mounted          => lookup('parapide_generated', node_uid, 'network_interfaces', 'ib0', 'mounted'),
          :vendor           => 'Mellanox',
          :version          => "MT25418",
          :driver           => lookup('parapide_generated', node_uid, 'network_interfaces', 'ib0', 'driver'),
          :network_address  => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
          :ip               => lookup('parapide_generated', node_uid, 'network_interfaces', 'ib0', 'ip'),
          :ip6              => lookup('parapide_generated', node_uid, 'network_interfaces', 'ib0', 'ip6'),
          :guid             => lookup('parapide_generated', node_uid, 'network_interfaces', 'ib0', 'guid')
        },
        {
          :interface        => lookup('parapide_generated', node_uid, 'network_interfaces', 'ib1', 'interface'),
          :rate             => lookup('parapide_generated', node_uid, 'network_interfaces', 'ib1', 'rate'),
          :device           => "ib1",
          :enabled          => lookup('parapide_generated', node_uid, 'network_interfaces', 'ib1', 'enabled'),
          :management       => lookup('parapide_generated', node_uid, 'network_interfaces', 'ib1', 'management'),
          :mountable        => lookup('parapide_generated', node_uid, 'network_interfaces', 'ib1', 'mountable'),
          :mounted          => lookup('parapide_generated', node_uid, 'network_interfaces', 'ib1', 'mounted'),
          :vendor           => 'Mellanox',
          :version          => "MT25418",
          :driver           => lookup('parapide_generated', node_uid, 'network_interfaces', 'ib1', 'driver'),
          :guid             => lookup('parapide_generated', node_uid, 'network_interfaces', 'ib1', 'guid')
        },
        {
          :interface            => 'Ethernet',
          :rate                 => 1.G,
          :network_address      => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip                   => lookup('parapide_generated', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac                  => lookup('parapide_generated', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :enabled              => true,
          :mounted              => false,
          :mountable            => false,
          :management           => true,
          :device               => "bmc"
        }]

        chassis({
          :serial        => lookup('parapide_generated', node_uid, 'chassis', 'serial_number'),
          :name          => lookup('parapide_generated', node_uid, 'chassis', 'product_name'),
          :manufacturer  => lookup('parapide_generated', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('parapide_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('parapide_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('parapide_generated', node_uid, 'bios', 'release_date')
        })

        bios({
          :version      => lookup('parapide_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('parapide_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('parapide_generated', node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu  => false
        })

        monitoring({
          :wattmeter    => false,
          :temperature  => true
        })

        sensors({
          :power => {
            :available => true,
            :via => {
              :pdu      => { :uid => lookup('parapide_manual', node_uid, 'pdu', 'pdu_name') },
            }
          },
          :temperature => {
            :available => true,
            :via => {
              :api  => { :metric => "ambient_temp" },
              :ipmi     => { :sensors => { :ambient => "/MB/T_AMB" } }
            }
          }
        })

        chassis({:serial_number => lookup('parapide', node_uid, 'chassis', 'serial_number')})

      end
    end
  end
end
