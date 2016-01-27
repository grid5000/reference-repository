site :nancy do |site_uid|

  cluster :grimoire do |cluster_uid|
    model "Dell PowerEdge R630"
    created_at Time.parse("2016-01-22").httpdate
    kavlan false
    queues ['admin', 'testing']

    8.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :core_flops => 0.G,
        :node_flops => 0.G
        })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :max_walltime => 0,
          :virtual      => lookup(node_uid, node_uid, 'supported_job_types', 'virtual'),
          :queues       => ['admin', 'testing']
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
          :name     => lookup(node_uid, node_uid, 'operating_system', 'name'),
          :release  => "Jessie",
          :version  => lookup(node_uid, node_uid, 'operating_system', 'version'),
          :kernel   => lookup(node_uid, node_uid, 'operating_system', 'kernel')
        })
        storage_devices [{
          :interface  => 'SCSI',
          :size       => lookup(node_uid, node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "megaraid_sas",
          :device     => lookup(node_uid, node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup(node_uid, node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => 'LSI Logic / Symbios Logic',
          :rev        => lookup(node_uid, node_uid, 'block_devices', 'sda', 'rev'),
          :storage    => 'HDD'
        },
        {
          :interface  => 'SCSI',
          :size       => lookup(node_uid, node_uid, 'block_devices', 'sdb', 'size'),
          :driver     => "megaraid_sas",
          :device     => lookup(node_uid, node_uid, 'block_devices', 'sdb', 'device'),
          :model      => lookup(node_uid, node_uid, 'block_devices', 'sdb', 'model'),
          :vendor     => 'LSI Logic / Symbios Logic',
          :rev        => lookup(node_uid, node_uid, 'block_devices', 'sdb', 'rev'),
          :storage    => 'HDD'
        }]

        network_adapters [{
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => true, 
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => true,
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :vendor           => 'Intel Corporation',
          :model            => '82599ES 10-Gigabit SFI/SFP+ Network Connection',
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'driver'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'mac'),
          :switch           => net_switch_lookup('nancy', 'grimoire', node_uid),
          :switch_port      => net_port_lookup('nancy', 'grimoire', node_uid),
          :ip               => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'ip'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr"
        },
        {
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 10.G,
          :enabled          => false, 
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => false,
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => false,
          :device           => "eth1",
          :vendor           => 'Intel Corporation',
          :model            => '82599ES 10-Gigabit SFI/SFP+ Network Connection',
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'mac'),
          :switch           => net_switch_lookup('nancy', 'grimoire', node_uid, 'eth1'),
          :switch_port      => net_port_lookup('nancy', 'grimoire', node_uid, 'eth1'),
        },
        {
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'interface'),
          :rate             => 10.G,
          :enabled          => false,
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'management'),
          :mountable        => false,
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'mounted'),
          :bridged          => false,
          :device           => "eth2",
          :vendor           => 'Intel Corporation',
          :model            => 'Ethernet 10G 2P X520 Adapter',
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'driver'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'mac'),
          :switch           => net_switch_lookup('nancy', 'grimoire', node_uid, 'eth2'),
          :switch_port      => net_port_lookup('nancy', 'grimoire', node_uid, 'eth2'),
        },
        {
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'eth3', 'interface'),
          :rate             => 10.G,
          :enabled          => false, 
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'eth3', 'management'),
          :mountable        => false,
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'eth3', 'mounted'),
          :bridged          => false,
          :device           => "eth3",
          :vendor           => 'Intel Corporation',
          :model            => 'Ethernet 10G 2P X520 Adapter',
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth3', 'driver'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth3', 'mac'),
          :switch           => net_switch_lookup('nancy', 'grimoire', node_uid, 'eth3'),
          :switch_port      => net_port_lookup('nancy', 'grimoire', node_uid, 'eth3'),
        },
        {
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'eth4', 'interface'),
          :rate             => 1.G,
          :enabled          => false, 
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'eth4', 'management'),
          :mountable        => false,
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'eth4', 'mounted'),
          :bridged          => false,
          :device           => "eth4",
          :vendor           => 'Intel Corporation',
          :model            => 'I350 Gigabit Network Connection',
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth4', 'driver'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth4', 'mac'),
          :switch           => net_switch_lookup('nancy', 'grimoire', node_uid, 'eth4'),
          :switch_port      => net_port_lookup('nancy', 'grimoire', node_uid, 'eth4'),
        },
        {
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'eth5', 'interface'),
          :rate             => 1.G,
          :enabled          => false, 
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'eth5', 'management'),
          :mountable        => false,
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'eth5', 'mounted'),
          :bridged          => false,
          :device           => "eth5",
          :vendor           => 'Intel Corporation',
          :model            => 'I350 Gigabit Network Connection',
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth5', 'driver'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth5', 'mac'),
          :switch           => net_switch_lookup('nancy', 'grimoire', node_uid, 'eth5'),
          :switch_port      => net_port_lookup('nancy', 'grimoire', node_uid, 'eth5'),
        },
        {
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'ib0', 'interface'),
          :rate             => lookup(node_uid, node_uid, 'network_interfaces', 'ib0', 'rate'),
          :enabled          => true, 
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'ib0', 'management'),
          :mountable        => true,
          :mounted          => true,
          :bridged          => true,
          :device           => "ib0",
          :vendor           => 'Mellanox',
          :model            => 'MT27500 Family [ConnectX-3]',
          :version          => lookup(node_uid, node_uid, 'network_interfaces', 'ib0', 'version'),
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'ib0', 'driver'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'ib0', 'mac'),
          :ip               => "172.18.71.#{i+1}",
          :ip6              => lookup(node_uid, node_uid, 'network_interfaces', 'ib0', 'ip6'),
          :network_address  => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
          :guid             => lookup(node_uid, node_uid, 'network_interfaces', 'ib0', 'guid'),
          :hwid             => lookup('grimoire_manual', node_uid, 'network_interfaces', 'ib0', 'hwid'),
          :switch           => "sgraoullyib",
          :ib_switch_card   => lookup('grimoire_manual', node_uid, 'network_interfaces', 'ib0', 'line_card'),
          :ib_switch_card_pos => lookup('grimoire_manual', node_uid, 'network_interfaces', 'ib0', 'position'),
        },
        {
          :interface            => 'Ethernet',
          :rate                 => 1.G,
          :network_address      => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip                   => "172.17.71.#{i+1}",
          :mac                  => lookup(node_uid, node_uid, 'network_interfaces', 'bmc', 'mac'),
          :enabled              => true,
          :mounted              => false,
          :mountable            => false,
          :management           => true,
          :device               => "bmc"
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

        sensors({
          :power => {
            :available => true,
            :via => { 
              :api => { :metric => 'power' },
              :pdu => [ {
                :uid => lookup('grimoire_manual', node_uid, 'pdu', 'pdu_name'),
                :port => lookup('grimoire_manual', node_uid, 'pdu', 'pdu_position'),
              } ]
            }
          }
        })

      end
    end
  end # cluster grimoire
end # nancy
