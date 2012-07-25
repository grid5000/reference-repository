site :nancy do |site_uid|

  cluster :graphene do |cluster_uid|
    model "Carri System 5393"
    created_at Time.parse("2011-01-20").httpdate

    144.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        serial lookup('graphene', node_uid, 'chassis', 'serial_number')
        supported_job_types({:deploy => true, :besteffort => true, :virtual => "ivt"})
        architecture({
          :smp_size => 1,
          :smt_size => 4,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "Intel",
          :model => "Intel Xeon",
          :version => "X3440",
          :clock_speed => 2.53.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 8.MiB
        })
        main_memory({
          :ram_size => 16.GiB,
          :virtual_size => nil
        })
        operating_system({
          :name => "Debian",
          :release => "6.0",
          :version => nil,
          :kernel => "2.6.32"
        })
        storage_devices [{
          :interface => 'SATA II',
          :size => 320.GB,
          :driver => "ahci",
          :device => "sda",
          :model => lookup('graphene', node_uid, 'block_devices' ,'sda',  'model'),
          :rev => lookup('graphene', node_uid, 'block_devices', 'sda', 'rev'),
        }]
        network_adapters [{
          :interface => 'Ethernet',
          :rate => 1.G,
          :device => "eth0",
          :enabled => true,
          :mounted => true,
          :mountable => true,
          :bridged => true,
          :management => false,
          :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip => lookup('graphene', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :mac => lookup('graphene', node_uid, 'network_interfaces', 'eth0', 'mac'),
          :switch => lookup('graphene', node_uid, 'network_interfaces', 'eth0', 'switch_name'),
          :switch_port => lookup('graphene', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :driver => "e1000e",
          :vendor => "intel",
          :version => "82574L"
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          #:device => "eth1",
          :enabled => false,
          #:mounted => false,
          :mac => lookup('graphene', node_uid, 'network_interfaces', 'eth1', 'mac'),
          #:management => false,
          #:driver => "e1000e",
          :vendor => "intel",
          :version => "82574L"
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          #:device => "eth2",
          :enabled => false,
          #:mounted => false,
          :mac => lookup('graphene', node_uid, 'network_interfaces', 'eth2', 'mac'),
          #:management => false,
          #:driver => "e1000e",
          :vendor => "intel",
          :version => "82574L"
        },
	{
          :interface => 'InfiniBand',
          :rate => 20.G,
          :device => "ib0",
          :enabled => true,
          :mounted => true,
          :mountable => true,
          :management => false,
          :ip => lookup('graphene', node_uid, 'network_interfaces', 'ib0', 'ip'),
          :guid => lookup('graphene', node_uid, 'network_interfaces', 'ib0', 'guid'),
          :network_address => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
	  :switch => "sgrapheneib",
          #:ib_switch_card => lookup('nancy',"#{node_uid}", 'switch_ib_card'),
          #:ib_switch_card_pos => lookup('nancy',"#{node_uid}", 'switch_ib_card_pos'),
          :driver => "mlx4_core",
          :vendor => "Mellanox",
          :version => "MT26418"
        },
        {
          :interface => 'InfiniBand',
          :rate => 20.G,
          :enabled => false,
          #:device => "ib1",
          #:driver => "mlx4_core",
          :vendor => "Mellanox",
          :version => "MT26418",
          #:mountable => false,
          #:mounted => false,
          #:management => false
          :guid => lookup('graphene', node_uid, 'network_interfaces', 'ib1', 'guid')
        },
        {
          :interface => 'Ethernet',
          :rate => 100.M,
          :enabled => true,
          :mounted => false,
          :mountable => false,
          :management => true,
          :vendor => "Tyan",
          :version => "AST2050",
          :device => "bmc",
          :ip => lookup('graphene', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac => lookup('graphene', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :network_address => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :switch => lookup('graphene', node_uid, 'network_interfaces', 'bmc', 'switch_name'),
          :switch_port => lookup('graphene', node_uid, 'network_interfaces', 'bmc', 'switch_port')
        }]
        pdu({
          :vendor => "American Power Conversion",
          :pdu => lookup('graphene', node_uid, 'pdu', 'pdu_name'),
          :pdu_port => lookup('graphene', node_uid, 'pdu', 'pdu_position')
        })
        bios({
          :version	=> lookup('graphene', node_uid, 'bios', 'version'),
          :vendor	=> "American Megatrends Inc.",
          :release_date	=> lookup('graphene', node_uid, 'bios', 'release_date')
        })

      end
    end
  end # cluster graphene
end
