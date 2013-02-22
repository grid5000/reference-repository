site :luxembourg do |site_uid|

  cluster :granduc do |cluster_uid|
    model "PowerEdge 1950"
    created_at Time.parse("2011-12-01").httpdate
    kavlan true

    22.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => "ivt"})
        architecture({
          :smp_size       => 2,
          :smt_size       => 8,
          :platform_type  => "x86_64"
          })
        processor({
          :vendor             => "Intel",
          :model              => "Intel Xeon",
          :version            => "L5335",
          :clock_speed        => 1995000000,
          :instruction_set    => "x86-64",
          :other_description  => "Intel(R) Xeon(R) CPU           L5335  @ 2.00GHz",
          :cache_l1           => 32768,
          :cache_l1i          => 32768,
          :cache_l1d          => 32768,
          :cache_l2           => 4194304,
          :cache_l3           => 0
        })
        main_memory({
          :ram_size     => 16864227328,
          :virtual_size => nil
        })
        operating_system({
          :name     => "debian",
          :release  => "Squeeze",
          :version  => "6.0",
          :kernel   => "#1 SMP Debian 3.2.35-2"
        })
        storage_devices [{
          :interface  => 'SAS',
          :size       => 146815733760,
          :driver     => "mptsas",
          :device     => "sda",
          :model      => lookup('granduc', node_uid, 'block_devices', 'sda', 'model'),
          :vendor     => lookup('granduc', node_uid, 'block_devices', 'sda', 'vendor'),
          :rev        => lookup('granduc', node_uid, 'block_devices', 'sda', 'rev')
        }]
        network_adapters [{
          :interface        => 'Ethernet',
          :rate             => 1.G,
          :enabled          => true,
          :management       => false,
          :mountable        => true,
          :mounted          => true,
          :bridged 	        => true,
          :device           => "eth0",
          :driver           => "bnx2",
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('granduc', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :switch           => "gw-luxembourg",
          :switch_port      => lookup('granduc', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('granduc', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => 'Ethernet',
          :rate             => 1.G,
          :enabled          => false,
          :management       => false,
          :device           => "eth1",
          :mountable        => true,
          :mounted          => false,
          :driver           => "bnx2",
          :network_address  => "#{node_uid}-eth1.#{site_uid}.grid5000.fr",
          :ip               => lookup('granduc', node_uid, 'network_interfaces', 'eth1', 'ip'),
          :switch           => "gw-luxembourg",
          :switch_port      => lookup('granduc', node_uid, 'network_interfaces', 'eth1', 'switch_port'),
          :mac              => lookup('granduc', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => 'Ethernet',
          :rate             => 10.G,
          :enabled          => true,
          :management       => false,
          :mountable        => true,
          :mounted          => true,
          :device           => "eth2",
          :driver           => "ixgbe",
          :switch           => "ul-grid5000-sw02",
          :switch_port      => lookup('granduc', node_uid, 'network_interfaces', 'eth2', 'switch_port'),
          :network_address  => "#{node_uid}-eth2.#{site_uid}.grid5000.fr",
          :ip               => lookup('granduc', node_uid, 'network_interfaces', 'eth2', 'ip'),
          :mac              => lookup('granduc', node_uid, 'network_interfaces', 'eth2', 'mac')
        },
        {
          :interface        => 'Ethernet',
          :rate             => 10.G,
          :enabled          => false,
          :management       => false,
          :mountable        => false,
          :mounted          => false,
          :device           => "eth3",
          :driver           => "ixgbe",
          :mac              => lookup('granduc', node_uid, 'network_interfaces', 'eth3', 'mac')
        },
        {
          :interface        => 'Ethernet',
          :rate             => 1.G,
          :enabled          => true,
          :management       => true,
          :mountable        => false,
          :mounted          => false,
          :device           => "bmc",
          :network_address  => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip               => lookup('granduc', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :switch           => "gw-luxembourg",
          :switch_port      => lookup('granduc', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('granduc', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :driver           => "bnx2"
         }]
        addressing_plan({
                :kavlan => "10.40.0.0/14",
                :virt   => "10.172.0.0/14"
                 })
        bios({
           :version      => lookup('granduc', node_uid, 'bios', 'version'),
           :vendor       => lookup('granduc', node_uid, 'bios', 'vendor'),
           :release_date => lookup('granduc', node_uid, 'bios', 'release_date')
        })
        gpu({
           :gpu  => false
            })
        chassis({
          :serial       => lookup('granduc', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('granduc', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('granduc', node_uid, 'chassis', 'manufacturer')
        })

        monitoring({
          :wattmeter  => false
        })
      end
    end
  end
end
