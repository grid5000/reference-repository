site :lyon do |site_uid|

  cluster :orion do |cluster_uid|
    model "Dell R720"
    created_at Time.parse("2012-09-14 12:00 GMT").httpdate
    kavlan true

    4.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
          :core_flops => 11900000000,
          :node_flops => 147200000000
        })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('orion_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('orion_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('orion_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('orion_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('orion_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('orion_generated', node_uid, 'processor', 'model'),
          :version            => lookup('orion_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('orion_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('orion_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('orion_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('orion_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('orion_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('orion_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('orion_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('orion_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('orion_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('orion_generated', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('orion_generated', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('orion_generated', node_uid, 'operating_system', 'kernel')
        })

        storage_devices [{
          :interface  => 'SCSI',
          :size       => lookup('orion_generated', node_uid, 'block_devices', 'sda', 'size'),
          :driver     => "megaraid_sas",
          :device     => lookup('orion_generated', node_uid, 'block_devices', 'sda', 'device'),
          :model      => lookup('orion_generated', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('orion_generated', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('orion_generated', node_uid, 'block_devices', 'sda', 'rev')
        }]

        network_adapters [{
          :interface        => lookup('orion_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => lookup('orion_generated', node_uid, 'network_interfaces', 'eth0', 'rate'),
          :enabled          => lookup('orion_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('orion_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('orion_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('orion_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => true,
          :device           => "eth0",
          :vendor           => 'Intel',
          :model            => 'Intel X520 DP 10Gb DA/SFP+ Server Adapter',
          :driver           => lookup('orion_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('orion_generated', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :ip6              => lookup('orion_generated', node_uid, 'network_interfaces', 'eth0', 'ip6'),
          :switch           => "force10",
          :switch_port      => lookup('orion_generated', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('orion_generated', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('orion_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('orion_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('orion_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('orion_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('orion_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :device           => "eth1",
          :bridged          => false,
          :vendor           => 'Intel',
          :model            => 'Intel X520 DP 10Gb DA/SFP+ Server Adapter',
          :driver           => lookup('orion_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :mac              => lookup('orion_generated', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => lookup('orion_generated', node_uid, 'network_interfaces', 'eth2', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('orion_generated', node_uid, 'network_interfaces', 'eth2', 'enabled'),
          :management       => lookup('orion_generated', node_uid, 'network_interfaces', 'eth2', 'management'),
          :mountable        => lookup('orion_generated', node_uid, 'network_interfaces', 'eth2', 'mountable'),
          :mounted          => lookup('orion_generated', node_uid, 'network_interfaces', 'eth2', 'mounted'),
          :device           => "eth2",
          :bridged          => false,
          :vendor           => 'Intel',
          :model            => 'Intel Ethernet I350 QP 1Gb',
          :driver           => lookup('orion_generated', node_uid, 'network_interfaces', 'eth2', 'driver'),
          :mac              => lookup('orion_generated', node_uid, 'network_interfaces', 'eth2', 'mac')
        },
        {
          :interface        => lookup('orion_generated', node_uid, 'network_interfaces', 'eth3', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('orion_generated', node_uid, 'network_interfaces', 'eth3', 'enabled'),
          :management       => lookup('orion_generated', node_uid, 'network_interfaces', 'eth3', 'management'),
          :mountable        => lookup('orion_generated', node_uid, 'network_interfaces', 'eth3', 'mountable'),
          :mounted          => lookup('orion_generated', node_uid, 'network_interfaces', 'eth3', 'mounted'),
          :device           => "eth3",
          :bridged          => false,
          :vendor           => 'Intel',
          :model            => 'Intel Ethernet I350 QP 1Gb',
          :driver           => lookup('orion_generated', node_uid, 'network_interfaces', 'eth3', 'driver'),
          :mac              => lookup('orion_generated', node_uid, 'network_interfaces', 'eth3', 'mac')
        },
        {
          :interface        => lookup('orion_generated', node_uid, 'network_interfaces', 'eth4', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('orion_generated', node_uid, 'network_interfaces', 'eth4', 'enabled'),
          :management       => lookup('orion_generated', node_uid, 'network_interfaces', 'eth4', 'management'),
          :mountable        => lookup('orion_generated', node_uid, 'network_interfaces', 'eth4', 'mountable'),
          :mounted          => lookup('orion_generated', node_uid, 'network_interfaces', 'eth4', 'mounted'),
          :device           => "eth4",
          :bridged          => false,
          :vendor           => 'Intel',
          :model            => 'Intel Ethernet I350 QP 1Gb',
          :driver           => lookup('orion_generated', node_uid, 'network_interfaces', 'eth4', 'driver'),
          :mac              => lookup('orion_generated', node_uid, 'network_interfaces', 'eth4', 'mac')
        },
        {
          :interface        => lookup('orion_generated', node_uid, 'network_interfaces', 'eth5', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('orion_generated', node_uid, 'network_interfaces', 'eth5', 'enabled'),
          :management       => lookup('orion_generated', node_uid, 'network_interfaces', 'eth5', 'management'),
          :mountable        => lookup('orion_generated', node_uid, 'network_interfaces', 'eth5', 'mountable'),
          :mounted          => lookup('orion_generated', node_uid, 'network_interfaces', 'eth5', 'mounted'),
          :device           => "eth5",
          :bridged          => false,
          :vendor           => 'Intel',
          :model            => 'Intel Ethernet I350 QP 1Gb',
          :driver           => lookup('orion_generated', node_uid, 'network_interfaces', 'eth5', 'driver'),
          :mac              => lookup('orion_generated', node_uid, 'network_interfaces', 'eth5', 'mac')
        },
        {
          :interface            => 'Ethernet',
          :rate                 => 1.G,
          :network_address      => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip                   => lookup('orion_generated', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac                  => lookup('orion_generated', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :enabled              => true,
          :mounted              => false,
          :mountable            => false,
          :management           => true,
          :device               => "bmc"
        }]

        chassis({
          :serial       => lookup('orion_generated', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('orion_generated', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('orion_generated', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('orion_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('orion_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('orion_generated', node_uid, 'bios', 'release_date')
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
        gpu({
          :gpu         =>  true,
          :gpu_count   =>  1,
          :gpu_vendor  =>  "Nvidia",
          :gpu_model   =>  "Tesla-M2075",
        })

      end
    end
  end # cluster orion
end
