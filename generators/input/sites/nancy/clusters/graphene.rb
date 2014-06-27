site :nancy do |site_uid|

  cluster :graphene do |cluster_uid|
    model "Carri System 5393"
    created_at Time.parse("2011-01-20").httpdate
    kavlan true
    production true

    144.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
          :core_flops => 8.024.G,
          :node_flops => 31.01.G
        })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('graphene_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('graphene_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('graphene_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('graphene_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('graphene_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('graphene_generated', node_uid, 'processor', 'model'),
          :version            => lookup('graphene_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('graphene_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('graphene_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('graphene_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('graphene_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('graphene_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('graphene_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('graphene_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('graphene_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('graphene_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('graphene_generated', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('graphene_generated', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('graphene_generated', node_uid, 'operating_system', 'kernel')
        })

        storage_devices [{
          :interface  => 'SATA II',
          :size       => lookup('graphene_generated', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "ahci",
          :device     => lookup('graphene_generated', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('graphene_generated', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('graphene_generated', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('graphene_generated', node_uid, 'block_devices', 'sda', 'rev')
        }]

        network_adapters [{
          :interface        => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :vendor           => "intel",
          :version          => "82574L",
          :driver           => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => net_switch_lookup('nancy', 'graphene', node_uid),
          :switch_port      => net_port_lookup('nancy', 'graphene', node_uid),
          :mac              => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth1', 'rate'),
          :enabled          => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor           => "intel",
          :version          => "82574L",
          :driver           => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth2', 'interface'),
          :enabled          => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth2', 'enabled'),
          :management       => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth2', 'management'),
          :mountable        => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth2', 'mountable'),
          :mounted          => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth2', 'mounted'),
          :bridged          => false,
          :device           => "eth2",
          :vendor           => "intel",
          :version          => "82574L",
          :driver           => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth2', 'driver'),
          :mac              => lookup('graphene_generated', node_uid, 'network_interfaces', 'eth2', 'mac')
        },
        {
          :interface        => lookup('graphene_generated', node_uid, 'network_interfaces', 'ib0', 'interface'),
          :rate             => lookup('graphene_generated', node_uid, 'network_interfaces', 'ib0', 'rate'),
          :device           => "ib0",
          :enabled          => lookup('graphene_generated', node_uid, 'network_interfaces', 'ib0', 'enabled'),
          :management       => lookup('graphene_generated', node_uid, 'network_interfaces', 'ib0', 'management'),
          :mountable        => lookup('graphene_generated', node_uid, 'network_interfaces', 'ib0', 'mountable'),
          :mounted          => lookup('graphene_generated', node_uid, 'network_interfaces', 'ib0', 'mounted'),
          :vendor           => 'Mellanox',
          :version          => "MT26418",
          :driver           => lookup('graphene_generated', node_uid, 'network_interfaces', 'ib0', 'driver'),
          :network_address  => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
          :ip               => lookup('graphene_generated', node_uid, 'network_interfaces', 'ib0', 'ip'),
          :ip6              => lookup('graphene_generated', node_uid, 'network_interfaces', 'ib0', 'ip6'),
          :guid             => lookup('graphene_generated', node_uid, 'network_interfaces', 'ib0', 'guid'),
          :switch           => "sgrapheneib",
        },
        {
          :interface        => lookup('graphene_generated', node_uid, 'network_interfaces', 'ib1', 'interface'),
          :rate             => lookup('graphene_generated', node_uid, 'network_interfaces', 'ib1', 'rate'),
          :device           => "ib1",
          :enabled          => lookup('graphene_generated', node_uid, 'network_interfaces', 'ib1', 'enabled'),
          :management       => lookup('graphene_generated', node_uid, 'network_interfaces', 'ib1', 'management'),
          :mountable        => lookup('graphene_generated', node_uid, 'network_interfaces', 'ib1', 'mountable'),
          :mounted          => lookup('graphene_generated', node_uid, 'network_interfaces', 'ib1', 'mounted'),
          :vendor           => 'Mellanox',
          :version          => "MT26418",
          :driver           => lookup('graphene_generated', node_uid, 'network_interfaces', 'ib1', 'driver'),
          :guid             => lookup('graphene_generated', node_uid, 'network_interfaces', 'ib1', 'guid')
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
          :ip => lookup('graphene_generated', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac => lookup('graphene_generated', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :network_address => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :switch => lookup('graphene_manual', node_uid, 'network_interfaces', 'bmc', 'switch_name'),
          :switch_port => lookup('graphene_manual', node_uid, 'network_interfaces', 'bmc', 'switch_port')
        }]

        chassis({
          :serial       => lookup('graphene_generated', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('graphene_generated', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('graphene_generated', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('graphene_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('graphene_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('graphene_generated', node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu  => false
        })

        if (105<=i+1 and i+1<=144) then
          sensors({
            :power => {
              :available => true,
              :via => {
                :api => { :metric => 'pdu' },
                :pdu => [ {
                  :uid  => lookup('graphene_manual', node_uid, 'pdu', 'pdu_name'),
                  :port => lookup('graphene_manual', node_uid, 'pdu', 'pdu_position'),
                } ]
              }
            }
          })
        else
          sensors({
            :power => {
              :available => true, # Set to true when pdu resources will be declared
              :via => {
                :pdu => [ { :uid  => lookup('graphene_manual', node_uid, 'pdu', 'pdu_name') } ]
              }
            }
          })
        end

      end
    end
  end # cluster graphene
end
