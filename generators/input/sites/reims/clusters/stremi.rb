site :reims do |site_uid|
  cluster :stremi do |cluster_uid|
     model "HP ProLiant DL165 G7"
     created_at Time.parse("2011-04-18").httpdate

     44.times do |i|
       node "#{cluster_uid}-#{i+1}" do |node_uid|
         supported_job_types({:deploy => true, :besteffort => true, :virtual => "amd-v"})
         architecture({
           :smp_size       => 2,
           :smt_size       => 24,
           :platform_type  => "amd64"
           })
         processor({
           :vendor             => "AMD",
           :model              => "AMD Opteron",
           :version            => "6164 HE",
           :clock_speed        => 1.7.G,
           :instruction_set    => "",
           :other_description  => "",
           :cache_l1           => nil,
           :cache_l1i          => nil,
           :cache_l1d          => nil,
           :cache_l2           => nil
         })
         main_memory({
           :ram_size     => 48.GiB,
           :virtual_size => nil
         })
         operating_system({
           :name     => "Debian",
           :release  => "6.0",
           :version  => nil,
           :kernel   => "2.6.32"
         })
         storage_devices [{
           :interface => 'SATA',
           :size => 250.GB,
           :driver => "ahci",
           :device => "sda"
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
           :ip               => lookup('stremi', node_uid, 'network_interfaces', 'bmc', 'ip'),
           :mac              => lookup('stremi', node_uid, 'network_interfaces', 'bmc', 'mac')
         },
         {
           :interface        => 'Ethernet',
           :rate             => 1.G,
           :enabled          => true,
           :mountable        => true,
           :mounted          => true,
           :bridged 	     => true,
           :device           => "eth0",
           :driver           => "igb",
           :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
           :ip               => lookup('stremi', node_uid, 'network_interfaces', 'eth0', 'ip'),
           :mac              => lookup('stremi', node_uid, 'network_interfaces', 'eth0', 'mac'),
           :switch           => "gw",
           :switch_port      => lookup('stremi', node_uid, 'network_interfaces', 'eth0', 'switch_port')
         },
         {
           :interface        => 'Ethernet',
           :rate             => 1.G,
           :enabled          => false,
           :device           => "eth1",
           :driver           => "igb",
           :mac              => lookup('stremi', node_uid, 'network_interfaces', 'eth1', 'mac')
         },
         {
           :interface        => 'Ethernet',
           :rate             => 1.G,
           :enabled          => false,
           :device           => "eth2",
           :driver           => "igb",
           :mac              => lookup('stremi', node_uid, 'network_interfaces', 'eth2', 'mac')
         },
         {
           :interface        => 'Ethernet',
           :rate             => 1.G,
           :enabled          => false,
           :device           => "eth3",
           :driver           => "igb",
           :mac              => lookup('stremi', node_uid, 'network_interfaces', 'eth3', 'mac')
         }]
 addressing_plan({
            :kavlan => "10.36.0.0/14",
            :virt   => "10.168.0.0/14"
             })


       end
     end
  end
end
