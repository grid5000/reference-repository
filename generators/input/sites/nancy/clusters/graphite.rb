site :nancy do |site_uid|

  cluster :graphite do |cluster_uid|
    model "Dell R720"
    created_at Time.parse("2013-12-5").httpdate
    kavlan true

    4.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
          :core_flops => 13.17.G,
          :node_flops => 187.90.G
        })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('graphite_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('graphite_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('graphite_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('graphite_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('graphite_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('graphite_generated', node_uid, 'processor', 'model'),
          :version            => lookup('graphite_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('graphite_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('graphite_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('graphite_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('graphite_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('graphite_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('graphite_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('graphite_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('graphite_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('graphite_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('graphite_generated', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('graphite_generated', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('graphite_generated', node_uid, 'operating_system', 'kernel')
        })

        storage_devices [{
          :interface  => 'SATA II',
          :size       => lookup('graphite_generated', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "megaraid_sas",
          :device     => lookup('graphite_generated', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('graphite_generated', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('graphite_generated', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('graphite_generated', node_uid, 'block_devices', 'sda', 'rev')
        },
	{
          :interface  => 'SATA II',
          :size       => lookup('graphite_generated', node_uid, 'block_devices', 'sdb', 'size'),
          :driver     => "megaraid_sas",
          :device     => lookup('graphite_generated', node_uid, 'block_devices', 'sdb', 'device'),
          :model      => lookup('graphite_generated', node_uid, 'block_devices', 'sdb', 'model'),
          :vendor     => lookup('graphite_generated', node_uid, 'block_devices', 'sdb', 'vendor'),
          :rev        => lookup('graphite_generated', node_uid, 'block_devices', 'sdb', 'rev')
        }]

        network_adapters [{
          :interface        => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :vendor           => "intel",
          :version          => "82599EB",
          :driver           => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => lookup('graphite_manual', node_uid, 'network_interfaces', 'eth0', 'switch_name'),
          :switch_port      => lookup('graphite_manual', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth1', 'rate'),
          :enabled          => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor           => "intel",
          :version          => "82599EB",
          :driver           => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth2', 'interface'),
          :rate             => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth2', 'rate'),
          :enabled          => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth2', 'enabled'),
          :management       => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth2', 'management'),
          :mountable        => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth2', 'mountable'),
          :mounted          => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth2', 'mounted'),
          :bridged          => false,
          :device           => "eth2",
          :vendor           => "intel",
          :version          => "I350",
          :driver           => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth2', 'driver'),
          :mac              => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth2', 'mac')
        },
        {
          :interface        => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth3', 'interface'),
          :rate             => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth3', 'rate'),
          :enabled          => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth3', 'enabled'),
          :management       => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth3', 'management'),
          :mountable        => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth3', 'mountable'),
          :mounted          => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth3', 'mounted'),
          :bridged          => false,
          :device           => "eth3",
          :vendor           => "intel",
          :version          => "I350",
          :driver           => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth3', 'driver'),
          :mac              => lookup('graphite_generated', node_uid, 'network_interfaces', 'eth3', 'mac')
        },
        {
          :interface => 'Ethernet',
          :rate => 100.M,
          :enabled => true,
          :mounted => false,
          :mountable => false,
          :management => true,
          :vendor => "DELL",
          :version => "IDRAC7",
          :device => "bmc",
          :ip => lookup('graphite_generated', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac => lookup('graphite_generated', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :network_address => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :switch => lookup('graphite_manual', node_uid, 'network_interfaces', 'bmc', 'switch_name'),
          :switch_port => lookup('graphite_manual', node_uid, 'network_interfaces', 'bmc', 'switch_port')
        }]

        chassis({
          :serial       => lookup('graphite_generated', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('graphite_generated', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('graphite_generated', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('graphite_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('graphite_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('graphite_generated', node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu  => false
        })

      end
    end
  end # cluster graphite
end
