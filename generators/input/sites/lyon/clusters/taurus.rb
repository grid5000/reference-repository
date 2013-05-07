site :lyon do |site_uid|

  cluster :taurus do |cluster_uid|
    model "Dell R720"
    created_at Time.parse("2012-09-14 12:00 GMT").httpdate
    kavlan true

    16.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :core_flops => 11770000000,
        :node_flops => 146900000000
      })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('taurus', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('taurus', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('taurus', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('taurus', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('taurus', node_uid, 'processor', 'vendor'),
          :model              => lookup('taurus', node_uid, 'processor', 'model'),
          :version            => lookup('taurus', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('taurus', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('taurus', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('taurus', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('taurus', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('taurus', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('taurus', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('taurus', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('taurus', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('taurus', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('taurus', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('taurus', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('taurus', node_uid, 'operating_system', 'kernel')
        })

        storage_devices [{
          :interface  => 'SCSI',
          :size       => lookup('taurus', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "megaraid_sas",
          :device     => lookup('taurus', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('taurus', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('taurus', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('taurus', node_uid, 'block_devices', 'sda', 'rev')
        }]

        network_adapters [{
          :interface        => lookup('taurus', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('taurus', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('taurus', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('taurus', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('taurus', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('taurus', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :vendor           => 'Intel',
          :model            => 'Intel X520 DP 10Gb DA/SFP+ Server Adapter',
          :driver           => lookup('taurus', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('taurus', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('taurus', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => "force10",
          :switch_port      => lookup('taurus', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('taurus', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('taurus', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('taurus', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('taurus', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('taurus', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('taurus', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :device           => "eth1",
          :bridged          => false,
          :vendor           => 'Intel',
          :model            => 'Intel X520 DP 10Gb DA/SFP+ Server Adapter',
          :driver           => lookup('taurus', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('taurus', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => lookup('taurus', node_uid, 'network_interfaces', 'eth2', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('taurus', node_uid, 'network_interfaces', 'eth2', 'enabled'),
          :management       => lookup('taurus', node_uid, 'network_interfaces', 'eth2', 'management'),
          :mountable        => lookup('taurus', node_uid, 'network_interfaces', 'eth2', 'mountable'),
          :mounted          => lookup('taurus', node_uid, 'network_interfaces', 'eth2', 'mounted'),
          :device           => "eth2",
          :bridged          => false,
          :vendor           => 'Intel',
          :model            => 'Intel Ethernet I350 QP 1Gb',
          :driver           => lookup('taurus', node_uid, 'network_interfaces', 'eth2', 'driver'),
          :mac              => lookup('taurus', node_uid, 'network_interfaces', 'eth2', 'mac')
        },
        {
          :interface        => lookup('taurus', node_uid, 'network_interfaces', 'eth3', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('taurus', node_uid, 'network_interfaces', 'eth3', 'enabled'),
          :management       => lookup('taurus', node_uid, 'network_interfaces', 'eth3', 'management'),
          :mountable        => lookup('taurus', node_uid, 'network_interfaces', 'eth3', 'mountable'),
          :mounted          => lookup('taurus', node_uid, 'network_interfaces', 'eth3', 'mounted'),
          :device           => "eth3",
          :bridged          => false,
          :vendor           => 'Intel',
          :model            => 'Intel Ethernet I350 QP 1Gb',
          :driver           => lookup('taurus', node_uid, 'network_interfaces', 'eth3', 'driver'),
          :mac              => lookup('taurus', node_uid, 'network_interfaces', 'eth3', 'mac')
        },
        {
          :interface        => lookup('taurus', node_uid, 'network_interfaces', 'eth4', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('taurus', node_uid, 'network_interfaces', 'eth4', 'enabled'),
          :management       => lookup('taurus', node_uid, 'network_interfaces', 'eth4', 'management'),
          :mountable        => lookup('taurus', node_uid, 'network_interfaces', 'eth4', 'mountable'),
          :mounted          => lookup('taurus', node_uid, 'network_interfaces', 'eth4', 'mounted'),
          :device           => "eth4",
          :bridged          => false,
          :vendor           => 'Intel',
          :model            => 'Intel Ethernet I350 QP 1Gb',
          :driver           => lookup('taurus', node_uid, 'network_interfaces', 'eth4', 'driver'),
          :mac              => lookup('taurus', node_uid, 'network_interfaces', 'eth4', 'mac')
        },
        {
          :interface        => lookup('taurus', node_uid, 'network_interfaces', 'eth5', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('taurus', node_uid, 'network_interfaces', 'eth5', 'enabled'),
          :management       => lookup('taurus', node_uid, 'network_interfaces', 'eth5', 'management'),
          :mountable        => lookup('taurus', node_uid, 'network_interfaces', 'eth5', 'mountable'),
          :mounted          => lookup('taurus', node_uid, 'network_interfaces', 'eth5', 'mounted'),
          :device           => "eth5",
          :bridged          => false,
          :vendor           => 'Intel',
          :model            => 'Intel Ethernet I350 QP 1Gb',
          :driver           => lookup('taurus', node_uid, 'network_interfaces', 'eth5', 'driver'),
          :mac              => lookup('taurus', node_uid, 'network_interfaces', 'eth5', 'mac')
        },
        {
          :interface            => 'Ethernet',
          :rate                 => 1.G,
          :network_address      => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip                   => lookup('taurus', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac                  => lookup('taurus', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :enabled              => true,
          :mounted              => false,
          :mountable            => false,
          :management           => true,
          :device               => "bmc"
        }]

        chassis({
          :serial       => lookup('taurus', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('taurus', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('taurus', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('taurus', node_uid, 'bios', 'version'),
          :vendor       => lookup('taurus', node_uid, 'bios', 'vendor'),
          :release_date => lookup('taurus', node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu  => false
        })

        monitoring({
          :wattmeter  => true
        })

        sensors({
          :power => {
            :available => true,
            :via => {
              :api => { :metric => 'pdu' },
              :www => { :url => 'https://helpdesk.grid5000.fr/supervision/lyon/wattmetre/GetWatts.php' },
            }
          }
        })

      end
    end
  end # cluster taurus
end
