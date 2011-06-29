site :nancy do |site_uid|

  cluster :graphene do |cluster_uid|
    model "Carri System 5393"
    created_at Time.parse("2011-01-20").httpdate

    144.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        serial lookup('nancy-graphene', node_uid, 'serial')
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
          :release => "5.0",
          :version => nil,
          :kernel => "2.6.26"
        })
        storage_devices [{
          :interface => 'SATA II',
          :size => 320.GB,
          :driver => "ahci",
          :device => "sda",
          :model => lookup('nancy-graphene', node_uid, 'disk_model'),
          :rev => lookup('nancy-graphene', node_uid, 'disk_rev')
        }]
        network_adapters [{
          :interface => 'Ethernet',
          :rate => 1.G,
          :device => "eth0",
          :enabled => true,
          :mounted => true,
          :mountable => true,
          :management => false,
          :switch => lookup('nancy-graphene', "#{node_uid}", 'switch_eth0'),
          :mac => lookup('nancy-graphene', "#{node_uid}", 'mac_eth0'),
          :switch_port => lookup('nancy-graphene', "#{node_uid}", 'switch_pos_eth0'),
          :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
          #:ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
          :ip => lookup('nancy-graphene', node_uid, 'ip_eth0'),
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
          :mac => lookup('nancy-graphene', "#{node_uid}", 'mac_eth1'),
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
          :mac => lookup('nancy-graphene', "#{node_uid}", 'mac_eth2'),
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
          :ip => lookup('nancy-graphene', "#{node_uid}", 'ip_ib'),
          :network_address => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
	  :switch => "sgrapheneib",
          #:ib_switch_card => lookup('nancy',"#{node_uid}", 'switch_ib_card'),
          #:ib_switch_card_pos => lookup('nancy',"#{node_uid}", 'switch_ib_card_pos'),
          :driver => "mlx4_core",
          :vendor => "Mellanox",
          :version => "MT26418",
	  :mac  => lookup('nancy-graphene', node_uid, 'guidib0')
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
          :mac	=> lookup('nancy-graphene', node_uid, 'guidib1')
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
          :ip => lookup('nancy-graphene', "#{node_uid}", 'ip_mgt'),
          :network_address => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :switch => lookup('nancy-graphene', "#{node_uid}", 'switch_ipmi'),
          :switch_port => lookup('nancy-graphene', "#{node_uid}", 'switch_ipmi_pos'),
          :mac => lookup('nancy-graphene', "#{node_uid}", 'mac_mgt'),
        }]
        pdu({
          :vendor => "American Power Conversion",
          :pdu => lookup('nancy-graphene', "#{node_uid}", 'pdu'),
          :pdu_port => lookup('nancy-graphene', "#{node_uid}", 'pdu_pos')
        })
        bios({
          :version	=> lookup('nancy-graphene', node_uid, 'bios_ver'),
          :vendor	=> "American Megatrends Inc.",
          :release_date	=> lookup('nancy-graphene', node_uid, 'bios_release')
        })

      end
    end
  end # cluster graphene
end
