site :lyon do |site_uid|

  cluster :taurus do |cluster_uid|
    model "Dell R720"
    created_at Time.parse("2012-09-14 12:00 GMT").httpdate
    kavlan true
    queues ['default', 'admin']

    16.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :core_flops => 11770000000,
        :node_flops => 146900000000
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
          :version  => "7",
          :kernel   => "3.16.0-4-amd64"
        })

        storage_devices [{
          :interface  => 'SCSI',
          :size       => lookup(node_uid, node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "megaraid_sas",
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
          :vendor           => 'Intel',
          :model            => 'Intel X520 DP 10Gb DA/SFP+ Server Adapter',
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => net_switch_lookup('lyon', 'taurus', node_uid, 'eth0'),
          :switch_port      => net_port_lookup('lyon', 'taurus', node_uid, 'eth0'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :device           => "eth1",
          :bridged          => false,
          :vendor           => 'Intel',
          :model            => 'Intel X520 DP 10Gb DA/SFP+ Server Adapter',
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'enabled'),
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'management'),
          :mountable        => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'mountable'),
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'mounted'),
          :device           => "eth2",
          :bridged          => false,
          :vendor           => 'Intel',
          :model            => 'Intel Ethernet I350 QP 1Gb',
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'driver'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth2', 'mac')
        },
        {
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'eth3', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup(node_uid, node_uid, 'network_interfaces', 'eth3', 'enabled'),
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'eth3', 'management'),
          :mountable        => lookup(node_uid, node_uid, 'network_interfaces', 'eth3', 'mountable'),
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'eth3', 'mounted'),
          :device           => "eth3",
          :bridged          => false,
          :vendor           => 'Intel',
          :model            => 'Intel Ethernet I350 QP 1Gb',
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth3', 'driver'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth3', 'mac')
        },
        {
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'eth4', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup(node_uid, node_uid, 'network_interfaces', 'eth4', 'enabled'),
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'eth4', 'management'),
          :mountable        => lookup(node_uid, node_uid, 'network_interfaces', 'eth4', 'mountable'),
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'eth4', 'mounted'),
          :device           => "eth4",
          :bridged          => false,
          :vendor           => 'Intel',
          :model            => 'Intel Ethernet I350 QP 1Gb',
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth4', 'driver'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth4', 'mac')
        },
        {
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'eth5', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup(node_uid, node_uid, 'network_interfaces', 'eth5', 'enabled'),
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'eth5', 'management'),
          :mountable        => lookup(node_uid, node_uid, 'network_interfaces', 'eth5', 'mountable'),
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'eth5', 'mounted'),
          :device           => "eth5",
          :bridged          => false,
          :vendor           => 'Intel',
          :model            => 'Intel Ethernet I350 QP 1Gb',
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth5', 'driver'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth5', 'mac')
        },
        {
          :interface            => 'Ethernet',
          :rate                 => 1.G,
          :network_address      => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip                   => lookup(node_uid, node_uid, 'network_interfaces', 'bmc', 'ip'),
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
            :per_outlets => true,
            :via => {
              :pdu      => [{
                :uid  => lookup('taurus_manual', node_uid, 'pdu', 'pdu_name'),
                :port => lookup('taurus_manual', node_uid, 'pdu', 'pdu_position'),
             }],
              :api => { :metric => 'power' },
              :www => { :url => 'http://wattmetre.lyon.grid5000.fr/GetWatts-json.php' },
            }
          }
        })

      end
    end
  end # cluster taurus
end
