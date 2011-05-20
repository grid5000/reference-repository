site :grenoble do |site_uid|
  name "Grenoble"
  location "Grenoble, France"
  web
  description ""
  latitude 45.1833
  longitude 5.7167
  email_contact
  sys_admin_contact
  security_contact
  user_support_contact
  ( %w{etch-x64-base-1.0 etch-x64-base-1.1 etch-x64-nfs-1.0 etch-x64-nfs-1.1 etch-x64-big-1.0 etch-x64-big-1.1 etch-x64-base-2.0 etch-x64-nfs-2.0 etch-x64-big-2.0} +
    %w{lenny-x64-base-0.9 lenny-x64-nfs-0.9 lenny-x64-big-0.9 lenny-x64-base-1.0 lenny-x64-nfs-1.0 lenny-x64-big-1.0 lenny-x64-base-2.0 lenny-x64-nfs-2.0 lenny-x64-big-2.0} +
    %w{lenny-x64-base-2.3 lenny-x64-big-2.3 lenny-x64-min-0.8 lenny-x64-nfs-2.3 lenny-x64-xen-2.3} +
    %w{squeeze-x64-base-0.8 squeeze-x64-big-0.8 squeeze-x64-min-0.8 squeeze-x64-nfs-0.8 squeeze-x64-xen-0.8} ).each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}

  cluster :genepi do |cluster_uid|
    model "Bull R422-E1"
    created_at Time.parse("2008-10-01").httpdate

    34.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => "ivt"})
        architecture({
          :smp_size => 2,
          :smt_size => 8,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "Intel",
          :model => "Intel Xeon",
          :version => "E5420 QC",
          :clock_speed => 2.5.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => nil
        })
        main_memory({
          :ram_size => 8.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SATA', :size => 160.GB, :driver => nil}
          ]
        network_adapters [{
          :interface => 'InfiniBand',
          :rate => 10.G,
          :device => "ib0",
          :enabled => true,
          :mountable => true,
          :mounted => true,
          :management => false,
          :vendor => 'Mellanox',
          :version => "InfiniHost MHGH29-XTC",
          :network_address => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
          :ip => dns_lookup("#{node_uid}-ib0.#{site_uid}.grid5000.fr"),
          :driver => "mlx4_core"
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :device => "eth0",
          :enabled => false,
          :management => false,
          :mac => lookup('grenoble', "#{node_uid}", 'mac_eth0'),
          :vendor => "Intel",
          :version => "Intel 80003ES2LAN Gigabit Ethernet Controller (Copper) (rev 01)"
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :device => "eth1",
          :enabled => true,
          :mountable => true,
          :mounted => true,
          :management => false,
          :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
          :mac => lookup('grenoble', "#{node_uid}", 'mac_eth1'),
          :vendor => "Intel",
          :version => "Intel 80003ES2LAN Gigabit Ethernet Controller (Copper) (rev 01)",
          :driver => "e1000e"
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :enabled => true,
          :mountable => false,
          :management => true,
          :network_address => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip => dns_lookup("#{node_uid}-bmc.#{site_uid}.grid5000.fr"),
          :mac => lookup('grenoble', "#{node_uid}", 'mac_mgt'),
          :vendor => "Peppercon AG (10437)",
          :version => "1.50"
        }]
      end
    end
  end

 cluster :adonis do |cluster_uid|
    created_at Time.parse("2010-09-02").httpdate
    10.times do |i|
      model "Bull R422-E2 dual mobo + Tesla S1070"
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => "ivt"})
        architecture({
          :smp_size => 2,
          :smt_size => 8,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "Intel",
          :model => "Intel Xeon",
          :version => "E5520",
          :clock_speed => 2.26.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => nil
        })
        main_memory({
          :ram_size => 24.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SATA', :size => 250.GB, :driver => nil}
          ]
        network_adapters [{
          :interface => 'InfiniBand',
          :rate => 40.G,
          :device => "ib0",
          :enabled => true,
          :mounted => true,
          :mountable => true,
          :management => false,
          :vendor => 'Mellanox',
          :version => "MT26428 ConnectX IB QDR, PCIe 2.0 5.0GT/s",
          :driver => "mlx4_core",
          :network_address => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
          :ip => dns_lookup("#{node_uid}-ib0.#{site_uid}.grid5000.fr")
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :device => "eth0",
          :enabled => true,
          :mounted => true,
          :mountable => true,
          :management => false,
          :vendor => 'Intel',
          :version => "Device 10c9 (rev 01)",
          :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr",
          :ip => dns_lookup("#{node_uid}-eth0.#{site_uid}.grid5000.fr"),
          :mac => lookup('grenoble', "#{node_uid}", 'mac_eth0'),
          :driver => "igb"
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :device => "eth1",
          :enabled => false,
          :mountable => false,
          :mounted => false,
          :management => false,
          :vendor => 'Intel',
          :version => "Device 10c9 (rev 01)",
          :mac => lookup('grenoble', "#{node_uid}", 'mac_eth1')
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :enabled => true,
          :mounted => false,
          :mountable => false,
          :management => true,
          :network_address => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip => dns_lookup("#{node_uid}-bmc.#{site_uid}.grid5000.fr"),
          :mac => lookup('grenoble', "#{node_uid}", 'mac_mgt'),
          :vendor => 'Super Micro Computer Inc.',
          :version => "1.15"
        }]
      end
    end
    2.times do |i|
      model "Bull R425-E2 4U + Tesla C2050"
      node "#{cluster_uid}-#{i+11}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => "ivt"})
        architecture({
          :smp_size => 2,
          :smt_size => 8,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "Intel",
          :model => "Intel Xeon",
          :version => "E5620",
          :clock_speed => 2.4.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => nil
        })
        main_memory({
          :ram_size => 24.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SATA', :size => 250.GB, :driver => nil}
          ]
        network_adapters [{
          :interface => 'InfiniBand',
          :rate => 40.G,
          :device => "ib0",
          :enabled => true,
          :mounted => true,
          :mountable => true,
          :management => false,
          :vendor => 'Mellanox',
          :version => "MT26428 ConnectX IB QDR, PCIe 2.0 5.0GT/s",
          :driver => "mlx4_core",
          :network_address => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
          :ip => dns_lookup("#{node_uid}-ib0.#{site_uid}.grid5000.fr")
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :device => "eth0",
          :enabled => true,
          :mountable => true,
          :mounted => true,
          :management => false,
          :vendor => 'Intel',
          :version => "Device 10c9 (rev 01)",
          :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr",
          :ip => dns_lookup("#{node_uid}-eth0.#{site_uid}.grid5000.fr"),
          :mac => lookup('grenoble', "#{node_uid}", 'mac_eth0'),
			 :driver => "igb"
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :device => "eth1",
          :enabled => false,
          :mountable => false,
          :mounted => false,
          :management => false,
          :vendor => 'Intel',
          :version => "Device 10c9 (rev 01)",
          :mac => lookup('grenoble', "#{node_uid}", 'mac_eth1')
        },
        {
          :interface => 'InfiniBand',
          :rate => 40.G,
          :device => "ib1",
          :enabled => true,
          :mounted => false,
          :mountable => true,
          :management => false,
          :vendor => 'Mellanox',
          :version => "MT26428 ConnectX IB QDR, PCIe 2.0 5.0GT/s  (rev a0)",
          :ip => "",
          :driver => "mlx4_core"
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :enabled => true,
          :mounted => false,
          :mountable => false,
          :management => true,
          :network_address => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip => dns_lookup("#{node_uid}-bmc.#{site_uid}.grid5000.fr"),
          :mac => lookup('grenoble', "#{node_uid}", 'mac_mgt'),
	  		 :vendor => 'Super Micro Computer Inc.',
			 :version => "1.33"
        }
		  ]
      end
    end
  end

  cluster :edel do |cluster_uid|
    model "Bull bullx B500 compute blades"
    created_at Time.parse("2008-10-03").httpdate

    72.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => "ivt"})
        architecture({
          :smp_size => 2,
          :smt_size => 8,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "Intel",
          :model => "Intel Xeon",
          :version => "E5520",
          :clock_speed => 2.27.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => nil
        })
        main_memory({
          :ram_size => 24.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SATA', :size => 60.GB, :driver => nil}
          ]
        network_adapters [{
          :interface => 'InfiniBand',
          :rate => 40.G,
          :enabled => true,
          :device => "ib0",
          :mounted => true,
          :mountable => true,
          :management => false,
          :vendor => 'Mellanox',
          :version => "MT26428 ConnectX IB QDR, PCIe 2.0 5.0GT/s (rev a0)",
          :network_address => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
          :ip => dns_lookup("#{node_uid}-ib0.#{site_uid}.grid5000.fr"),
          :driver => "mlx4_core"
        },
        {
          :interface => 'InfiniBand',
          :rate => 40.G,
          :enabled => true,
          :device => "ib1",
          :mounted => false,
          :mountable => true,
          :management => false,
          :vendor => 'Mellanox',
          :version => "MT26428 ConnectX IB QDR, PCIe 2.0 5.0GT/s (rev a0)",
          :driver => "mlx4_core",
          :ip => ""

        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :enabled => true,
          :device => "eth0",
          :mounted => true,
          :mountable => true,
          :management => false,
          :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr",
          :ip => dns_lookup("#{node_uid}-eth0.#{site_uid}.grid5000.fr"),
          :mac => lookup('grenoble', "#{node_uid}", 'mac_eth0'),
          :vendor => "Intel",
          :version => "Device 10e7 (rev 01)",
          :driver => "igb"
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :device => "eth1",
          :enabled => false,
          :mounted => false,
          :mountable => false,
          :management => false,
          :vendor => "Intel",
          :version => "Device 10e7 (rev 01)",
          :mac => lookup('grenoble', "#{node_uid}", 'mac_eth1')
        },
        {
          :interface => 'Ethernet',
          :rate => 100.M,
          :enabled => true,
          :mounted => false,
          :mountable => false,
          :management => true,
          :network_address => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip => dns_lookup("#{node_uid}-bmc.#{site_uid}.grid5000.fr"),
          :mac => lookup('grenoble', "#{node_uid}", 'mac_mgt'),
          :vendor => "Unknown",
          :version => "1.7"
        }]
      end
    end
  end
end
