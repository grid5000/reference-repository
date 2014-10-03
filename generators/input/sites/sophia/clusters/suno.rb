site :sophia do |site_uid|

  cluster :suno do |cluster_uid|
    model "Dell PowerEdge R410"
    created_at Time.parse("2010-01-27").httpdate
    kavlan true
    production true

    45.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
          :core_flops => 7140000000,
          :node_flops => 55460000000
        })



        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('suno_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('suno_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('suno_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('suno_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('suno_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('suno_generated', node_uid, 'processor', 'model'),
          :version            => lookup('suno_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('suno_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('suno_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('suno_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('suno_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('suno_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('suno_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('suno_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('suno_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('suno_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => "debian",
          :release  => "Wheezy",
          :version  => "7",
          :kernel   => "3.2.0-4-amd64"
        })

        storage_devices [{
          :interface  => 'SATA',
          :size       => lookup('suno_generated', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "megaraid_sas",
          :device     => lookup('suno_generated', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('suno_generated', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('suno_generated', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('suno_generated', node_uid, 'block_devices', 'sda', 'rev'),
          :raid => "0"
        }]
        network_adapters [{
          :interface        => lookup('suno_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('suno_generated', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('suno_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('suno_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('suno_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('suno_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :vendor           => 'Broadcom',
          :version          => 'NetXtremeII BCM5716',
          :driver           => lookup('suno_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('suno_generated', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('suno_generated', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => net_switch_lookup('sophia', 'suno', node_uid),
          :switch_port      => net_port_lookup('sophia', 'suno', node_uid),
          :mac              => lookup('suno_generated', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('suno_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('suno_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('suno_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('suno_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('suno_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor           => 'Broadcom',
          :version          => 'NetXtremeII BCM5716',
          :driver           => lookup('suno_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :ip               => lookup('suno_generated', node_uid, 'network_interfaces', 'eth1', 'ip'),
          :mac              => lookup('suno_generated', node_uid, 'network_interfaces', 'eth1', 'mac')
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
          :ip               => lookup('suno_generated', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :vendor           => "Unknown",
          :version          => "1.7",
          :mac              => lookup('suno_generated', node_uid, 'network_interfaces', 'bmc', 'mac')
        }]

        chassis({
          :serial       => lookup('suno_generated', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('suno_generated', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('suno_generated', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('suno_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('suno_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('suno_generated', node_uid, 'bios', 'release_date')
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
