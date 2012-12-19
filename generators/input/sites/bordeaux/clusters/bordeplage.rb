site :bordeaux do |site_uid|

  cluster :bordeplage do |cluster_uid|
    model "Dell PowerEdge 1855"
    kavlan false
    created_at nil

    51.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => false})
        architecture({
          :smp_size 	 => 2,
          :smt_size 	 => 2,
          :platform_type => "x86_64"
          })
        processor({
          :vendor 	     => "Intel",
          :model 	     => "Intel Xeon",
          :version 	     => "EM64T",
          :clock_speed 	     => 3.G,
          :instruction_set   => "",
          :other_description => "",
          :cache_l1 	     => nil,
          :cache_l1i 	     => nil,
          :cache_l1d 	     => 16.KiB,
          :cache_l2 	     => 1.MiB
        })
        main_memory({
          :ram_size 	=> 2.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name 	=> "Debian",
          :release 	=> "Squeeze",
          :version 	=> "6.0",
	  :kernel   	=> "2.6.32"
        })
        storage_devices [{
      	  :interface 	=> 'SCSI',
	  :size 	=> 70.GB,
	  :driver 	=> "mptspi",
	  :device       => "sda",
	  :model        => lookup('bordeplage', node_uid, 'block_devices', 'sda', 'model'),
	  :rev          => lookup('bordeplage', node_uid, 'block_devices', 'sda', 'rev')
	}]
        network_adapters [{
	  :interface 	=> 'Ethernet',
	  :rate 	=> 1.G,
          :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
	  :ip 		=> lookup('bordeplage', node_uid, 'network_interfaces', 'eth0', 'ip'),
	  :mac 		=> lookup('bordeplage', node_uid, 'network_interfaces', 'eth0', 'mac'),
          :vendor 	=> "Intel",
	  :version 	=> "82546GB Gigabit Ethernet Controller",
          :enabled 	=> true,
          :switch => "gw Pro-Curve-HP",
          :mounted 	=> true,
	  :mountable 	=> true,
          :bridged      => true,
	  :driver 	=> "e1000",
	  :management 	=> false,
	  :device 	=> "eth0"
	},
        {
	  :interface 	=> 'Ethernet',
	  :rate 	=> 1.G,
          :network_address => "#{node_uid}-eth1.#{site_uid}.grid5000.fr",
	  :ip 		=> lookup('bordeplage', node_uid, 'network_interfaces', 'eth1', 'ip'),
	  :mac 		=> lookup('bordeplage', node_uid, 'network_interfaces', 'eth1', 'mac'),
          :vendor 	=> "Intel",
	  :version 	=> "82546GB Gigabit Ethernet Controller",
          :enabled 	=> true,
	  :mounted 	=> false,
	  :mountable 	=> true,
	  :driver 	=> "e1000",
	  :management 	=> false,
	  :device 	=> "eth1",
	},
	{
	  :interface 	=> 'InfiniBand',
	  :rate 	=> 10.G,
          :network_address => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
	  :ip 		=> lookup('bordeplage', node_uid, 'network_interfaces', 'ib0', 'ip'),
	  :guid 	=> lookup('bordeplage', node_uid, 'network_interfaces', 'ib0', 'guid'),
          :vendor 	=> 'Mellanox',
	  :version 	=> "InfiniHost MT25208",
          :enabled 	=> true,
	  :mountable 	=> true,
	  :mounted 	=> true,
	  :driver 	=> "ib_mthca",
	  :management 	=> false,
	  :device 	=> "ib0"
	},
	{
	  :interface 	=> 'InfiniBand',
	  :rate 	=> 10.G,
	  :guid 	=> lookup('bordeplage', node_uid, 'network_interfaces', 'ib1', 'guid'),
          :vendor 	=> 'Mellanox',
	  :version 	=> "InfiniHost MT25208",
          :enabled 	=> false,
	  :device 	=> "ib1"
	},
	{
	  :interface 	=> 'Ethernet',
	  :rate 	=> 100.M,
          :network_address => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
	  :ip 		=> lookup('bordeplage', node_uid, 'network_interfaces', 'bmc', 'ip'),
	  :guid 	=> lookup('bordeplage', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :enabled 	=> true,
	  :mountable 	=> false,
	  :mounted 	=> false,
	  :management 	=> true,
	  :device 	=> "bmc"
	}]
	bios({
	  :version	=> lookup('bordeplage', node_uid, 'bios', 'version'),
	  :vendor	=> lookup('bordeplage', node_uid, 'bios', 'vendor'),
	  :release_date => lookup('bordeplage', node_uid, 'bios', 'release_date')
	})
	chassis({
	  :serial       => lookup('bordeplage', node_uid, 'chassis', 'serial_number'),
	  :name		=> lookup('bordeplage', node_uid, 'chassis', 'product_name')
	})

  gpu({
    :gpu  => false
     })

    monitoring({
      :wattmeter  => false
    })
      end
    end
  end # cluster bordeplage
  #misc "Motherboard Bios version: A05 ;IPMI version 1.5: Firware revision 1.6"
end
