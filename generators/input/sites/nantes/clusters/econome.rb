site :nantes do |site_uid|

  cluster :econome do |cluster_uid|
    model "Dell PowerEdge C6220"
    created_at Time.parse("2014-04-16").httpdate
    kavlan true
    production true

    18.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
          :core_flops => 0,
          :node_flops => 0
        })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('econome_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('econome_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('econome_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('econome_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('econome_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('econome_generated', node_uid, 'processor', 'model'),
          :version            => lookup('econome_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('econome_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('econome_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('econome_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('econome_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('econome_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('econome_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('econome_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('econome_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('econome_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('econome_generated', node_uid, 'operating_system', 'name'),
          :release  => 'Wheezy',
          :version  => lookup('econome_generated', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('econome_generated', node_uid, 'operating_system', 'kernel')
        })

        storage_devices [{
          :interface => 'SATA',
          :driver    => "ahci",
          :device    => lookup('econome_generated', node_uid, 'block_devices' ,'sda', 'device'),
          :size      => lookup('econome_generated', node_uid, 'block_devices' ,'sda', 'size'),
          :model     => lookup('econome_generated', node_uid, 'block_devices' ,'sda', 'model'),
          :rev       => lookup('econome_generated', node_uid, 'block_devices', 'sda', 'rev'),
        }]

        network_adapters [        {
          :interface        => lookup('econome_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('econome_generated', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :rate             => 10.G,
          :device           => "eth0",
          :enabled          => lookup('econome_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('econome_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('econome_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('econome_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :vendor           => "Intel",
          :version          => '82599EB 10-Gigabit SFI/SFP+ Network Connection',
          :driver           => lookup('econome_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :mac              => lookup('econome_generated', node_uid, 'network_interfaces', 'eth0', 'mac'),
          :switch_port      => net_port_lookup('nantes', 'econome', node_uid, 'eth0'),
          :switch           => net_switch_lookup('nantes', 'econome', node_uid, 'eth0'),
        },
        {
          :interface        => lookup('econome_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 10.G,
          :rate             => lookup('econome_generated', node_uid, 'network_interfaces', 'eth1', 'rate'),
          :enabled          => lookup('econome_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('econome_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('econome_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('econome_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor           => "Intel",
          :version          => '82599EB 10-Gigabit SFI/SFP+ Network Connection',
          :driver           => lookup('econome_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('econome_generated', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => lookup('econome_generated', node_uid, 'network_interfaces', 'eth2', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('econome_generated', node_uid, 'network_interfaces', 'eth2', 'enabled'),
          :management       => lookup('econome_generated', node_uid, 'network_interfaces', 'eth2', 'management'),
          :mountable        => false,
          :mounted          => lookup('econome_generated', node_uid, 'network_interfaces', 'eth2', 'mounted'),
          :bridged          => false,
          :device           => "eth2",
          :vendor           => "Intel",
          :version          => "Intel Corporation",
          :driver           => lookup('econome_generated', node_uid, 'network_interfaces', 'eth2', 'driver'),
          :mac              => lookup('econome_generated', node_uid, 'network_interfaces', 'eth2', 'mac'),
        },
        {
          :interface        => lookup('econome_generated', node_uid, 'network_interfaces', 'eth3', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('econome_generated', node_uid, 'network_interfaces', 'eth3', 'enabled'),
          :management       => lookup('econome_generated', node_uid, 'network_interfaces', 'eth3', 'management'),
          :mountable        => lookup('econome_generated', node_uid, 'network_interfaces', 'eth3', 'mountable'),
          :mounted          => lookup('econome_generated', node_uid, 'network_interfaces', 'eth3', 'mounted'),
          :bridged          => false,
          :device           => "eth3",
          :vendor           => "Intel",
          :version          => "Intel Corporation",
          :driver           => lookup('econome_generated', node_uid, 'network_interfaces', 'eth3', 'driver'),
          :mac              => lookup('econome_generated', node_uid, 'network_interfaces', 'eth3', 'mac')
        },
        {
          :interface            => 'Ethernet',
          :network_address  => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :rate                 => 1.G,
          :network_address      => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip                   => lookup('econome_generated', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac                  => lookup('econome_generated', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :enabled              => true,
          :mounted              => false,
          :mountable            => false,
          :management           => true,
          :device               => "bmc",
        }]


        chassis({
          :serial       => lookup('econome_generated', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('econome_generated', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('econome_generated', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('econome_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('econome_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('econome_generated', node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu => false
        })

        monitoring({
          :wattmeter => false,
        })

        sensors({
          :power => {
            :available => false,
          }
        })

      end
    end
  end
end

