site :bordeaux do |site_uid|

  cluster :bordereau do |cluster_uid|
    model "IBM System x3455"
    created_at Time.parse("2007-10-01 12:00 GMT").httpdate
    misc "IPMI 2.0"
    kavlan false
    93.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => false})
        architecture({
                       :smp_size 		=> 2,
                       :smt_size 		=> 4,
          :platform_type	=> "x86_64"
                     })
        processor({
                    :vendor 		=> "AMD",
                    :model 		=> "AMD Opteron",
                    :version 		=> "2218",
                    :clock_speed 		=> 2.6.G,
                    :instruction_set 	=> "x86-64",
                    :other_description 	=> "",
                    :cache_l1 		=> nil,
                    :cache_l1i 		=> 64.KiB,
                    :cache_l1d 		=> 64.KiB,
                    :cache_l2 		=> 1.MiB
                  })
        main_memory({
                      :ram_size 		=> 4.GiB,
                      :virtual_size 	=> nil
                    })
        operating_system({
                           :name 		=> "Debian",
                           :release 		=> "Squeeze",
                           :version 		=> "6.0",
                           :Kernel 		=> "2.6.32"
                         })
        storage_devices [{
                           :interface 		=> 'SATA',
                           :size 		=> 80.GB,
                           :device		=> "sda",
                           :driver 		=> "sata_svw",
                           :model 		=> lookup('bordereau', node_uid, 'block_devices', 'sda', 'model'),
                           :rev 			=> lookup('bordereau', node_uid, 'block_devices', 'sda', 'rev'),
                         }]
        network_adapters [{
                            :interface 		=> 'Ethernet',
                            :rate 		=> 1.G,
                            :network_address 	=> "#{node_uid}.#{site_uid}.grid5000.fr",
                            :ip 			=> lookup('bordereau', node_uid, 'network_interfaces', 'eth0', 'ip'),
                            :mac 			=> lookup('bordereau', node_uid, 'network_interfaces', 'eth0', 'mac'),
                            :switch_port => lookup('bordereau',node_uid, 'network_interfaces', 'eth0', 'switch_port'),
                            :vendor 		=> "Broadcom",
                            :version 		=> "BCM5704",
                            :enabled 		=> true,
                            :switch     => "gw Pro-Curve-HP",
                            :mounted 		=> true,
                            :mountable 	=> true,
                            :bridged 		=> true,
                            :driver 		=> "tg3",
                            :management => false,
                            :device 		=> "eth0"
                          },
                          {
                            :interface 		=> 'Ethernet',
                            :rate 		=> 1.G,
                            :network_address 	=> "#{node_uid}-eth1.#{site_uid}.grid5000.fr",
                            :ip 			=> lookup('bordereau', node_uid, 'network_interfaces', 'eth1', 'ip'),
                            :mac 			=> lookup('bordereau', node_uid, 'network_interfaces', 'eth1', 'mac'),
                            :vendor 		=> "Broadcom",
                            :version 		=> "BCM5704",
                            :enabled 		=> true,
                            :mounted 		=> false,
                            :mountable 		=> true,
                            :driver 		=> "tg3",
                            :management 		=> false,
                            :device 		=> "eth1"
                          },
                          {
                            :interface 		=> 'Ethernet',
                            :rate 		=> 100.M,
                            :network_address 	=> "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
                            :ip 			=> lookup('bordereau', node_uid, 'network_interfaces', 'bmc', 'ip'),
                            :mac 			=> lookup('bordereau', node_uid, 'network_interfaces', 'bmc', 'mac'),
                            :enabled 		=> true,
                            :mounted 		=> false,
                            :mountable 		=> false,
                            :management 		=> true,
                            :device 		=> "bmc"
                          }]
	bios({
               :version              => lookup('bordereau', node_uid, 'bios', 'version'),
               :vendor               => lookup('bordereau', node_uid, 'bios', 'vendor'),
               :release_date         => lookup('bordereau', node_uid, 'bios', 'release_date')
             })
	chassis({
                  :serial               => lookup('bordereau', node_uid, 'chassis', 'serial_number'),
                  :name                 => lookup('bordereau', node_uid, 'chassis', 'product_name')
                })
     gpu({
            :gpu  => false
              })

    monitoring({
                  :wattmeter  => false
                })
      end
    end
  end # cluster bordereau
end
