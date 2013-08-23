site :lille do |site_uid|

  cluster :chimint do |cluster_uid|
    model "Dell PowerEdge R410"
    created_at Time.parse("2011-03-25").httpdate
    kavlan true

    20.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :core_flops => 7456000000,
        :node_flops => 55610000000
      })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('chimint_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('chimint_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('chimint_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('chimint_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('chimint_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('chimint_generated', node_uid, 'processor', 'model'),
          :version            => lookup('chimint_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('chimint_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('chimint_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('chimint_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('chimint_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('chimint_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('chimint_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('chimint_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('chimint_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('chimint_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('chimint_generated', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('chimint_generated', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('chimint_generated', node_uid, 'operating_system', 'kernel')
        })

        storage_devices [{
          :interface  => 'SATA',
          :size       => lookup('chimint_generated', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "megaraid_sas",
          :device     => lookup('chimint_generated', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('chimint_generated', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('chimint_generated', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('chimint_generated', node_uid, 'block_devices', 'sda', 'rev'),
          :raid       => "0"
        }]

        network_adapters [{
          :interface        => lookup('chimint_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('chimint_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('chimint_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('chimint_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('chimint_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :vendor           => 'Broadcom',
          :version          => 'NetXtreme II BCM5716',
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :switch           => 'gw-lille',
          :ip               => lookup('chimint_generated', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('chimint_generated', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch_port      => lookup('chimint_manual', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :driver           => lookup('chimint_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :mac              => lookup('chimint_generated', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('chimint_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => lookup('chimint_generated', node_uid, 'network_interfaces', 'eth1', 'rate'),
          :enabled          => lookup('chimint_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('chimint_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('chimint_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('chimint_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor           => 'Broadcom',
          :version          => 'NetXtreme II BCM5716',
          :driver           => lookup('chimint_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('chimint_generated', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface            => 'Ethernet',
          :rate                 => 1.G,
          :network_address      => "#{node_uid}-impi.#{site_uid}.grid5000.fr",
          :ip                   => lookup('chimint_generated', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac                  => lookup('chimint_generated', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :switch               => lookup('chimint_generated', node_uid, 'network_interfaces', 'bmc', 'switch_name'),
          :switch_port          => lookup('chimint_generated', node_uid, 'network_interfaces', 'bmc', 'switch_port'),
          :enabled              => true,
          :mounted              => false,
          :mountable            => false,
          :management           => true,
          :device               => "bmc",
        }]

        chassis({
          :serial       => lookup('chimint_generated', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('chimint_generated', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('chimint_generated', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('chimint_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('chimint_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('chimint_generated', node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu  => false
        })

        monitoring({
          :wattmeter  => false
        })

      end
    end
  end # cluster chimint
end
