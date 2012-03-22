site :reims do |site_uid|
  name "Reims"
  location "Reims, France"
  web ""
  description ""
  latitude 49.244508
  longitude 4.062714
  email_contact "reims-staff@lists.grid5000.fr"
  sys_admin_contact "reims-staff@lists.grid5000.fr"
  security_contact "reims-staff@lists.grid5000.fr"
  user_support_contact "reims-staff@lists.grid5000.fr"
  ( %w{sid-x64-base-1.0 sid-x64-base-1.1 sid-x64-nfs-1.0 sid-x64-nfs-1.1 sid-x64-big-1.1} + 
    %w{etch-x64-base-1.0 etch-x64-base-1.1 etch-x64-nfs-1.0 etch-x64-nfs-1.1 etch-x64-big-1.0 etch-x64-big-1.1 etch-x64-base-2.0 etch-x64-nfs-2.0 etch-x64-big-2.0} +
    %w{lenny-x64-base-0.9 lenny-x64-nfs-0.9 lenny-x64-big-0.9 lenny-x64-base-1.0 lenny-x64-nfs-1.0 lenny-x64-big-1.0 lenny-x64-base-2.0 lenny-x64-nfs-2.0 lenny-x64-big-2.0} +
    %w{lenny-x64-base-2.3 lenny-x64-big-2.3 lenny-x64-min-0.8 lenny-x64-nfs-2.3 lenny-x64-xen-2.3}  ).each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}
 
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
           :ip               => lookup('reims-stremi', node_uid, 'network_interfaces', 'bmc', 'ip'),
           :mac              => lookup('reims-stremi', node_uid, 'network_interfaces', 'bmc', 'mac')
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
           :ip               => lookup('reims-stremi', node_uid, 'network_interfaces', 'eth0', 'ip'),
           :mac              => lookup('reims-stremi', node_uid, 'network_interfaces', 'eth0', 'mac'),
           :switch           => "gw",
           :switch_port      => lookup('reims-stremi', node_uid, 'network_interfaces', 'eth0', 'switch_port')
         },
         {
           :interface        => 'Ethernet',
           :rate             => 1.G,
           :enabled          => false,
           :device           => "eth1",
           :driver           => "igb",
           :mac              => lookup('reims-stremi', node_uid, 'network_interfaces', 'eth1', 'mac')
         },
         {
           :interface        => 'Ethernet',
           :rate             => 1.G,
           :enabled          => false,
           :device           => "eth2",
           :driver           => "igb",
           :mac              => lookup('reims-stremi', node_uid, 'network_interfaces', 'eth2', 'mac')
         },
         {
           :interface        => 'Ethernet',
           :rate             => 1.G,
           :enabled          => false,
           :device           => "eth3",
           :driver           => "igb",
           :mac              => lookup('reims-stremi', node_uid, 'network_interfaces', 'eth3', 'mac')
         }]
       end
     end


  end

end
