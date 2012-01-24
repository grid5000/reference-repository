site :rennes do |site_uid|

  cluster :paradent do |cluster_uid|
    model "Carry System"
    created_at Time.parse("2009-02-01").httpdate

    64.times do |i|
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
          :version            => "L5420",
          :clock_speed        => 2.5.G,
          :instruction_set    => "",
          :other_description  => "",
          :cache_l1           => nil,
          :cache_l1i          => nil,
          :cache_l1d          => nil,
          :cache_l2           => nil
        })
        main_memory({
          :ram_size     => 32.GiB,
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
          :size       => 160.GB,
          :driver     => "ata_piix",
          :device     => "sda",
          :model      => lookup('rennes-paradent', node_uid, 'block_device', 'sda', 'model'),
          :rev        => lookup('rennes-paradent', node_uid, 'block_device', 'sda', 'rev')
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
           :ip               => lookup('rennes-paradent', node_uid, 'network_interfaces', 'bmc', 'ip'),
           :mac              => lookup('rennes-paradent', node_uid, 'network_interfaces', 'bmc', 'mac')
         },
         {
          :interface        => 'Ethernet',
          :rate             => 1.G,
          :enabled          => true,
          :management       => false,
          :mountable        => true,
          :mounted          => true,
          :device           => "eth0",
          :driver           => "e1000e",
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('rennes-paradent', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :switch           => lookup('rennes-paradent', node_uid, 'network_interfaces', 'eth0', 'switch_name'),
          :switch_port      => lookup('rennes-paradent', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac              => lookup('rennes-paradent', node_uid, 'network_interfaces', 'eth0', 'mac'),
          :vendor           => "Intel",
          :version          => "80003ES2LAN"
        },
        {
          :interface  => 'Ethernet',
          :rate       => 1.G,
          :enabled    => false,
          :device     => "eth1",
          :driver     => "e1000e",
          :vendor           => "Intel",
          :version          => "80003ES2LAN",
          :mac        => lookup('rennes-paradent', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
         {
          :interface        => 'Ethernet',
          :rate             => 100.M,
          :enabled          => true,
          :management       => true,
          :mountable        => false,
          :mounted          => false,
          :device           => "bmc",
          :network_address  => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip               => lookup('rennes-paradent', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac              => lookup('rennes-paradent', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :vendor           => "Tyan",
          :version          => "M3296"
        }]
        bios({
           :version      => lookup('rennes-paradent', node_uid, 'bios', 'version'),
           :vendor       => lookup('rennes-paradent', node_uid, 'bios', 'vendor'),
           :release_date => lookup('rennes-paradent', node_uid, 'bios', 'release_date')
         })
         #chassis({:serial_number => lookup('rennes-paradent', node_uid, 'chassis', 'serial_number')})
      end
    end
  end

end
