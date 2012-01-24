site :rennes do |site_uid|
  
  cluster :parapide do |cluster_uid|
    model "SUN FIRE X2270"
    created_at Time.parse("2010-01-25").httpdate
    
    25.times do |i|
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
          :version            => "X5570",
          :clock_speed        => 2.93.G,
          :instruction_set    => "",
          :other_description  => "",
          :cache_l1           => nil,
          :cache_l1i          => nil,
          :cache_l1d          => nil,
          :cache_l2           => nil
        })
        main_memory({
          :ram_size     => 24.GiB,
          :virtual_size => nil
        })
        operating_system({
          :name     => "Debian",
          :release  => "5.0",
          :version  => nil,
          :kernel   => "2.6.26"
        })
        storage_devices [{
          :interface  => 'SATA',
          :size       => 500.GB,
          :driver     => "ahci",
          :device     => "sda",
          :model      => lookup('rennes-parapide', node_uid, 'block_device', 'sda', 'model'),
          :rev        => lookup('rennes-parapide', node_uid, 'block_device', 'sda', 'rev')
        }]
        network_adapters [{
           :interface        => 'Ethernet',
           :rate             => 1.G,
           :enabled          => true,
           :management       => true,
           :mountable        => false,
           :mounted          => false,
           :device           => "bmc",
           :network_address  => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
           :ip               => lookup('rennes-parapide', node_uid, 'network_interfaces', 'bmc', 'ip'),
           :mac              => lookup('rennes-parapide', node_uid, 'network_interfaces', 'bmc', 'mac')
         },
         {
          :interface        => 'Ethernet',
          :rate             => 1.G,
          :enabled          => true,
          :mountable        => true,
          :mounted          => true,
          :device           => "eth0",
          :driver           => "igb",
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('rennes-parapide', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :switch           => lookup('rennes-parapide', node_uid, 'network_interfaces', 'eth0', 'switch_name'),
          :switch_port      => lookup('rennes-parapide', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('rennes-parapide', node_uid, 'network_interfaces', 'eth0', 'mac'),
          :vendor           => "Intel",
          :version          => "82575EB"
        },
        {
          :interface  => 'Ethernet',
          :rate       => 1.G,
          :enabled    => false,
          :mountable  => false,
          :mounted    => false,
          :device     => "eth1",
          :driver     => "igb",
          :mac        => lookup('rennes-parapide', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => 'Infiniband',
          :rate             => 10.G,
          :enabled          => true,
          :mountable        => true,
          :mounted          => true,
          :device           => "ib0",
          :driver           => "mlx4_core",
          :vendor           => "Mellanox",
          :version          => "MT25418",
          :network_address  => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
          :ip               => lookup('rennes-parapide', node_uid, 'network_interfaces', 'ib0', 'ip'),
          :mac              => lookup('rennes-parapide', node_uid, 'network_interfaces', 'ib0', 'guid')
        },
        {
          :interface        => 'Infiniband',
          :rate             => 10.G,
          :enabled          => false,
          :device           => "ib1",
          :driver           => "mlx4_core",
          :vendor           => "Mellanox",
          :version          => "MT25418",
          :mac              => lookup('rennes-parapide', node_uid, 'network_interfaces', 'ib1', 'guid')
        }]
        bios({
           :version      => lookup('rennes-parapide', node_uid, 'bios', 'version'),
           :vendor       => lookup('rennes-parapide', node_uid, 'bios', 'vendor'),
           :release_date => lookup('rennes-parapide', node_uid, 'bios', 'release_date')
         })
         chassis({:serial_number => lookup('rennes-parapide', node_uid, 'chassis', 'serial_number')})
      end
    end
    
  end
  
end
