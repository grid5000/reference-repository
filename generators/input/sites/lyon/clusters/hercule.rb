site :lyon do |site_uid|

  cluster :hercule do |cluster_uid|
    model "Dell C6220"
    created_at Time.parse("2012-10-02 12:00 GMT").httpdate
    kavlan true
    production true

    4.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :core_flops => 10170000000,
        :node_flops => 127100000000
      })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('hercule_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('hercule_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('hercule_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('hercule_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('hercule_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('hercule_generated', node_uid, 'processor', 'model'),
          :version            => lookup('hercule_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('hercule_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('hercule_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('hercule_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('hercule_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('hercule_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('hercule_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('hercule_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('hercule_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('hercule_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('hercule_generated', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('hercule_generated', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('hercule_generated', node_uid, 'operating_system', 'kernel')
        })

        storage_devices [{
          :interface => 'SATA',
          :driver => "ahci",
          :device => lookup('hercule_generated', node_uid, 'block_devices' ,'sda',  'device'),
          :size => lookup('hercule_generated', node_uid, 'block_devices' ,'sda',  'size'),
          :model => lookup('hercule_generated', node_uid, 'block_devices' ,'sda',  'model'),
          :rev => lookup('hercule_generated', node_uid, 'block_devices', 'sda', 'rev'),
        },
        {
          :interface => 'SATA',
          :driver => "ahci",
          :device => lookup('hercule_generated', node_uid, 'block_devices' ,'sdb',  'device'),
          :size => lookup('hercule_generated', node_uid, 'block_devices' ,'sdb',  'size'),
          :model => lookup('hercule_generated', node_uid, 'block_devices' ,'sdb',  'model'),
          :rev => lookup('hercule_generated', node_uid, 'block_devices', 'sdb', 'rev'),
        },
        {
          :interface => 'SATA',
          :driver => "ahci",
          :device => lookup('hercule_generated', node_uid, 'block_devices' ,'sdc',  'device'),
          :size => lookup('hercule_generated', node_uid, 'block_devices' ,'sdc',  'size'),
          :model => lookup('hercule_generated', node_uid, 'block_devices' ,'sdc',  'model'),
          :rev => lookup('hercule_generated', node_uid, 'block_devices', 'sdc', 'rev'),
        }]

        network_adapters [        {
          :interface        => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => 1.G,
          :device           => "eth0",
          :enabled          => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => false,
          :vendor           => "Intel",
          :version          => '82599EB 10-Gigabit SFI/SFP+ Network Connection',
          :driver           => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :mac              => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth1', 'rate'),
          :enabled          => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => true,
          :device           => "eth1",
          :vendor           => "Intel",
          :version          => '82599EB 10-Gigabit SFI/SFP+ Network Connection',
          :driver           => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth1', 'ip'),
          :ip6              => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth1', 'ip6'),
          :switch           => "force10",
          :switch_port      => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth1', 'switch_port'),
          :mac              => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth2', 'interface'),
          :rate             => 100.M,
          :enabled          => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth2', 'enabled'),
          :management       => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth2', 'management'),
          :mountable        => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth2', 'mountable'),
          :mounted          => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth2', 'mounted'),
          :bridged          => false,
          :device           => "eth2",
          :vendor           => "Intel",
          :version          => "Intel Corporation",
          :driver           => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth2', 'driver'),
          :switch           => "pat",
          :switch_port      => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth2', 'switch_port'),
          :mac              => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth2', 'mac')
        },
        {
          :interface        => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth3', 'interface'),
          :rate             => 100.M,
          :enabled          => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth3', 'enabled'),
          :management       => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth3', 'management'),
          :mountable        => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth3', 'mountable'),
          :mounted          => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth3', 'mounted'),
          :bridged          => false,
          :device           => "eth3",
          :vendor           => "Intel",
          :version          => "Intel Corporation",
          :driver           => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth3', 'driver'),
          :switch           => "pat",
          :switch_port      => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth3', 'switch_port'),
          :mac              => lookup('hercule_generated', node_uid, 'network_interfaces', 'eth3', 'mac')
        },
        {
          :interface            => 'Ethernet',
          :rate                 => 1.G,
          :network_address      => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip                   => lookup('hercule_generated', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac                  => lookup('hercule_generated', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :enabled              => true,
          :mounted              => false,
          :mountable            => false,
          :management           => true,
          :device               => "bmc",
        }]

        chassis({
          :serial       => lookup('hercule_generated', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('hercule_generated', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('hercule_generated', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('hercule_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('hercule_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('hercule_generated', node_uid, 'bios', 'release_date')
        })

        monitoring({
          :wattmeter  => 'shared',
        })

        sensors({
          :power => {
            :available => true,
            :per_outlets => false,
            :via => {
              :api => { :metric => 'pdu_shared' },
              :www => { :url => 'http://wattmetre.lyon.grid5000.fr/GetWatts-json.php' },
            }
          }
        })
      end
    end
  end # cluster hercule
end
