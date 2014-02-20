site :rennes do |site_uid|

  cluster :paradent do |cluster_uid|
    model "Carry System"
    created_at Time.parse("2009-02-01").httpdate
    kavlan true

    64.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :core_flops => 8095000000,
        :node_flops => 55530000000
      })

        architecture({
          :smp_size       => 2,
          :smt_size       => 8,
          :platform_type  => "x86_64"
        })

        processor({
          :vendor             => "Intel",
          :model              => "Intel Xeon",
          :version            => "L5420",
          :clock_speed        => 2.5.G,
          :instruction_set    => "",
          :other_description  => "",
          :cache_l1           => nil,
          :cache_l1i          => nil,
          :cache_l1d          => nil,
          :cache_l2           => nil
        })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('paradent_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('paradent_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('paradent_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('paradent_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('paradent_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('paradent_generated', node_uid, 'processor', 'model'),
          :version            => lookup('paradent_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('paradent_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('paradent_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('paradent_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('paradent_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('paradent_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('paradent_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('paradent_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('paradent_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('paradent_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('paradent_generated', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('paradent_generated', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('paradent_generated', node_uid, 'operating_system', 'kernel')
        })

        storage_devices [{
          :interface  => 'SATA',
          :size       => lookup('paradent_generated', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "ata_piix",
          :device     => lookup('paradent_generated', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('paradent_generated', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('paradent_generated', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('paradent_generated', node_uid, 'block_devices', 'sda', 'rev')
        }]

        network_adapters [{
          :interface        => lookup('paradent_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('paradent_generated', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('paradent_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('paradent_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('paradent_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('paradent_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :vendor           => "Intel",
          :version          => "80003ES2LAN",
          :device           => "eth0",
          :driver           => lookup('paradent_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('paradent_generated', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('paradent_generated', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => lookup('paradent_manual', node_uid, 'network_interfaces', 'eth0', 'switch_name'),
          :switch_port      => lookup('paradent_manual', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('paradent_generated', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('paradent_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('paradent_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('paradent_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('paradent_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('paradent_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor           => "Intel",
          :version          => "80003ES2LAN",
          :driver           => lookup('paradent_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('paradent_generated', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        { :interface            => 'Ethernet',
          :rate                 => 100.M,
          :mac                  => lookup('paradent_generated', node_uid, 'network_interfaces','bmc','mac'),
          :vendor               => "Tyan",
          :version              => "M3296",
          :enabled              => true,
          :management           => true,
          :mountable            => false,
          :mounted              => false,
          :network_address      => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip                   => lookup('paradent_generated', node_uid,'network_interfaces','bmc','ip'),
        }]

        chassis({
          :serial       => lookup('paradent_generated', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('paradent_generated', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('paradent_generated', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('paradent_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('paradent_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('paradent_generated', node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu  => false
        })

        sensors({
          :power => {
            :available => true,
            :via => {
              :pdu      => [{ :uid => lookup('paradent_manual', node_uid, 'pdu', 'pdu_name') }]
            }
          },
          :temperature => {
            :available => true,
            :via => {
              :ganglia  => { :metric => "ambient_temp" },
              :ipmi     => { :sensors => { :ambient => "Thermistor2 TEMP" } }
            }
          }
        })

      end
    end
  end
end
