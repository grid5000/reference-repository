site :bordeaux do |site_uid|

  cluster :borderline do |cluster_uid|
    model "IBM System x3755"
    created_at Time.parse("2007-10-01 12:00 GMT").httpdate
    misc "IPMI 2.0"
    kavla false
    10.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => "amd-v"})
        architecture({
          :smp_size 	 	=> 4,
          :smt_size 	 	=> 8,
          :platform_type 	=> "x86_64"
          })
        processor({
          :vendor 	 	=> "AMD",
          :model 		=> "AMD Opteron",
          :version 		=> "8218",
          :clock_speed 		=> 2.6.G,
          :instruction_set 	=> "x86-64",
          :other_description 	=> "",
          :cache_l1 		=> nil,
          :cache_l1i 		=> 64.KiB,
          :cache_l1d 		=> 64.KiB,
          :cache_l2 		=> 2.MiB
	})
        main_memory({
          :ram_size 		=> 32.GiB,
          :virtual_size 	=> nil
        })
        operating_system({
          :name 		=> "Debian",
          :release 		=> "Squeeze",
          :version 		=> "6.0",
	  :kernel 		=> "2.6.32"
        })
        storage_devices [{
	  :interface 		=> "SAS",
	  :size 		=> 600.GB,
	  :driver 		=> "aacraid",
	  :device 		=> "sda",
	  :model        	=> lookup('borderline', node_uid, 'block_devices', 'sda', 'model'),
	  :rev        		=> lookup('borderline', node_uid, 'block_devices', 'sda', 'rev')
	}]
        network_adapters [{
	  :interface 		=> 'Ethernet',
	  :rate 		=> 1.G,
	  :network_address 	=> "#{node_uid}.#{site_uid}.grid5000.fr",
	  :ip 			=> lookup('borderline', node_uid, 'network_interfaces', 'eth0', 'ip'),
	  :mac 			=> lookup('borderline', node_uid, 'network_interfaces', 'eth0', 'mac'),
	  :vendor 		=> "Broadcom",
	  :version 		=> "NetXtreme II BCM5708",
	  :switch     => "gw Pro-Curve-HP",
    :enabled 		=> true,
	  :mounted 		=> true,
	  :mountable 		=> true,
          :bridged 		=> true,
	  :driver 		=> "bnx2",
	  :management 		=> false,
	  :device 		=> "eth0"
	},
        {
	  :interface 		=> 'Ethernet',
	  :rate 		=> 1.G,
          :network_address 	=> "#{node_uid}-eth1.#{site_uid}.grid5000.fr",
	  :ip 			=> lookup('borderline', node_uid, 'network_interfaces', 'eth1', 'ip'),
	  :mac 			=> lookup('borderline', node_uid, 'network_interfaces', 'eth1', 'mac'),
	  :vendor 		=> "Broadcom",
	  :version 		=> "NetXtreme II BCM5708",
          :enabled 		=> true,
	  :mounted 		=> false,
	  :mountable 		=> true,
	  :driver 		=> "bnx2",
	  :management 		=> false,
	  :device 		=> "eth1"
	},
	{
	  :interface 		=> 'InfiniBand',
	  :rate 		=> 10.G,
	  :network_address 	=> "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
	  :ip 			=> lookup('borderline', node_uid, 'network_interfaces', 'ib0', 'ip'),
	  :guid 		=> lookup('borderline', node_uid, 'network_interfaces', 'ib0', 'guid'),
	  :vendor 		=> 'Mellanox',
	  :version 		=> "InfiniHost MT25208",
	  :enabled 		=> true,
	  :mountable 		=> true,
	  :mounted 		=> true,
	  :driver 		=> "ib_mthca",
	  :management 		=> false,
	  :device 		=> "ib0"
	},
	{
	  :interface 		=> 'InfiniBand',
	  :rate 		=> 10.G,
	  :guid 		=> lookup('borderline', node_uid, 'network_interfaces', 'ib1', 'guid'),
	  :vendor 		=> 'Mellanox',
	  :version 		=> "InfiniHost MT25208",
	  :enabled 		=> false,
	  :device 		=> "ib1"
	},
	{
	  :interface 		=> 'Myrinet',
	  :rate 		=> 10.G,
	  :network_address 	=> "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
	  :ip 			=> lookup('borderline', node_uid, 'network_interfaces', 'myri0', 'ip'),
	  :mac 			=> lookup('borderline', node_uid, 'network_interfaces', 'myri0', 'mac'),
	  :vendor 		=> 'Myrinet',
	  :version 		=> "10G-PCIE-8A-C",
	  :enabled 		=> true,
	  :mountable 		=> true,
	  :mounted 		=> true,
	  :driver 		=> "mx_driver",
	  :management 		=> false,
	  :device 		=> "myri0"
	},
	{
	  :interface 		=> 'Ethernet',
	  :rate 		=> 100.M,
	  :network_address 	=> "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
	  :ip 			=> lookup('borderline', node_uid, 'network_interfaces', 'bmc', 'ip'),
	  :mac 			=> lookup('borderline', node_uid, 'network_interfaces', 'bmc', 'mac'),
	  :enabled 		=> true,
	  :mounted 		=> false,
	  :mountable 		=> false,
	  :management 		=> true,
	  :device 		=> "bmc"
	}]
        bios({
          :version      	=> lookup('borderline', node_uid, 'bios', 'version'),
          :vendor       	=> lookup('borderline', node_uid, 'bios', 'vendor'),
          :release_date 	=> lookup('borderline', node_uid, 'bios', 'release_date')
        })
	chassis({
	  :serial		=> lookup('borderline', node_uid, 'chassis', 'serial_number'),
	  :name			=> lookup('borderline', node_uid, 'chassis', 'product_name')
	})
  gpu({
    :gpu  => false
      })


    monitoring({
      :wattmeter  => false
    })
      end
    end
  end # cluster borderline
end
