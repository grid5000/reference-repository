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
          :virtual      => lookup(node_uid, node_uid, 'supported_job_types', 'virtual'),
          :max_walltime => 0,
          :queues       => ['default', 'admin']
        })

        architecture({
          :smp_size       => lookup(node_uid, node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup(node_uid, node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup(node_uid, node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup(node_uid, node_uid, 'processor', 'vendor'),
          :model              => lookup(node_uid, node_uid, 'processor', 'model'),
          :version            => lookup(node_uid, node_uid, 'processor', 'version'),
          :clock_speed        => lookup(node_uid, node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup(node_uid, node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup(node_uid, node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup(node_uid, node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup(node_uid, node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup(node_uid, node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup(node_uid, node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup(node_uid, node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup(node_uid, node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => "debian",
          :release  => "Jessie",
          :version  => "8.2",
          :kernel   => "3.16.0-4-amd64"
        })

        storage_devices [{
          :interface  => 'SATA II',
          :size       => lookup(node_uid, node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "ahci",
          :device     => lookup(node_uid, node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup(node_uid, node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup(node_uid, node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup(node_uid, node_uid, 'block_devices', 'sda', 'rev'),
          :storage    => 'HDD'
        }]

        network_adapters [{
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :vendor           => "intel",
          :version          => "82574L",
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => net_switch_lookup('nancy', 'graphene', node_uid),
          :switch_port      => net_port_lookup('nancy', 'graphene', node_uid),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'rate'),
          :enabled          => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor           => "intel",
          :version          => "82574L",
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'interface'),
          :enabled          => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'enabled'),
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'management'),
          :mountable        => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'mountable'),
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'mounted'),
          :bridged          => false,
          :device           => "eth2",
          :vendor           => "intel",
          :version          => "82574L",
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'driver'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'mac')
        },
        {
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'ib0', 'interface'),
          :rate             => lookup(node_uid, node_uid, 'network_interfaces', 'ib0', 'rate'),
          :device           => "ib0",
          :enabled          => lookup(node_uid, node_uid, 'network_interfaces', 'ib0', 'enabled'),
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'ib0', 'management'),
          :mountable        => lookup(node_uid, node_uid, 'network_interfaces', 'ib0', 'mountable'),
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'ib0', 'mounted'),
          :vendor           => 'Mellanox',
          :version          => "MT26418",
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'ib0', 'driver'),
          :network_address  => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
          :ip               => lookup(node_uid, node_uid, 'network_interfaces', 'ib0', 'ip'),
          :ip6              => lookup(node_uid, node_uid, 'network_interfaces', 'ib0', 'ip6'),
          :guid             => lookup(node_uid, node_uid, 'network_interfaces', 'ib0', 'guid'),
          :switch           => "sgrapheneib",
        },
        {
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'ib1', 'interface'),
          :rate             => lookup(node_uid, node_uid, 'network_interfaces', 'ib1', 'rate'),
          :device           => "ib1",
          :enabled          => lookup(node_uid, node_uid, 'network_interfaces', 'ib1', 'enabled'),
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'ib1', 'management'),
          :mountable        => lookup(node_uid, node_uid, 'network_interfaces', 'ib1', 'mountable'),
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'ib1', 'mounted'),
          :vendor           => 'Mellanox',
          :version          => "MT26418",
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'ib1', 'driver'),
          :guid             => lookup(node_uid, node_uid, 'network_interfaces', 'ib1', 'guid')
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
          :ip => lookup(node_uid, node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac => lookup(node_uid, node_uid, 'network_interfaces', 'bmc', 'mac'),
          :network_address => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :switch => lookup('graphene_manual', node_uid, 'network_interfaces', 'bmc', 'switch_name'),
          :switch_port => lookup('graphene_manual', node_uid, 'network_interfaces', 'bmc', 'switch_port')
        }]

        chassis({
          :serial       => lookup(node_uid, node_uid, 'chassis', 'serial_number'),
          :name         => lookup(node_uid, node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup(node_uid, node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup(node_uid, node_uid, 'bios', 'version'),
          :vendor       => lookup(node_uid, node_uid, 'bios', 'vendor'),
          :release_date => lookup(node_uid, node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu  => false
        })

        if (105<=i+1 and i+1<=144) then
          sensors({
            :power => {
              :available => true,
              :via => {
                :api => { :metric => 'power' },
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
