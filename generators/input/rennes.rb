site :rennes do |site_uid|
  name "Rennes"
  location "Rennes, France"
  web "http://www.irisa.fr"
  description ""
  latitude 48.1000
  longitude -1.6667
  email_contact "rennes-staff@lists.grid5000.fr"
  sys_admin_contact "rennes-staff@lists.grid5000.fr"
  security_contact "rennes-staff@lists.grid5000.fr"
  user_support_contact "rennes-staff@lists.grid5000.fr"
  ( %w{sid-x64-base-1.0 sid-x64-base-1.1 sid-x64-nfs-1.0 sid-x64-nfs-1.1 sid-x64-big-1.1} + 
    %w{etch-x64-base-1.0 etch-x64-base-1.1 etch-x64-nfs-1.0 etch-x64-nfs-1.1 etch-x64-big-1.0 etch-x64-big-1.1 etch-x64-base-2.0 etch-x64-nfs-2.0 etch-x64-big-2.0} +
    %w{lenny-x64-base-0.9 lenny-x64-nfs-0.9 lenny-x64-big-0.9 lenny-x64-base-1.0 lenny-x64-nfs-1.0 lenny-x64-big-1.0 lenny-x64-base-2.0 lenny-x64-nfs-2.0 lenny-x64-big-2.0}  ).each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}
 compilation_server false
  
  cluster :paramount do |cluster_uid|
    model "Dell PowerEdge 1950"
    created_at Time.parse("2007-09-01").httpdate
    33.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => "ivt"})
        architecture({
          :smp_size => 2,
          :smt_size => 4,
          :platform_type => "x86_64"
        })
        
        processor({
          :vendor => "Intel",
          :model => "Intel Xeon",
          :version => "5148 LV",
          :clock_speed => 2.33.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => nil          
        })
        main_memory({
          :ram_size => 8.GiB,
          :virtual_size => nil
        })
        operating_system({
          :name => "Debian",
          :release => "5.0",
          :version => nil,
          :kernel => "2.6.26"
        })
        storage_devices [{
          :interface => 'SATA',
          :size => 600.GB,
          :driver => "megaraid_sas",
          :raid => "0"
        }]
        network_adapters [{
          :interface => 'Ethernet',
          :rate => 1.G,
          :enabled => true,
          :mountable => true,
          :mounted => true,
          :device => "eth0",
          :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
          :vendor => "Broadcom",
          :version => "NetXtreme II BCM5708",
          :driver => "bnx2",
          :switch => "c6509-grid"
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :enabled => false,
          :mountable => false,
          :mounted => false,
          :device => "eth1",
          :vendor => "Broadcom",
          :version => "NetXtreme II BCM5708",
          :driver => "bnx2"
        },
        {
          :interface => 'Myrinet',
          :rate => 10.G,
          :enabled => true,
          :mountable => true,
          :mounted => true,
          :device => "myri0"
          :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
          :ip => dns_lookup("#{node_uid}-myri0.#{site_uid}.grid5000.fr"), 
          :vendor => 'Myrinet',
          :version => "10G-PCIE-8A-C"
        }]
      end
    end
  end
  
  cluster :paradent do |cluster_uid|
    model "Carry System"
    created_at Time.parse("2009-02-01").httpdate
    
    64.times do |i|
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
          :version => "L5420",
          :clock_speed => 2.5.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => nil
        })
        main_memory({
          :ram_size => 32.GiB,
          :virtual_size => nil
        })
        operating_system({
          :name => "Debian",
          :release => "5.0",
          :version => nil,
          :kernel => "2.6.26"
        })
        storage_devices [{
          :interface => 'SATA',
          :size => 160.GB,
          :driver => "ata_piix"
        }]
        network_adapters [{
          :interface => 'Ethernet',
          :rate => 1.G,
          :enabled => true,
          :mountable => true,
          :mounted => true,
          :device = "eth0",
          :driver => "e1000e",
          :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
          :switch => "c6509-grid"
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :enabled => false,
          :mountable => false,
          :mounted => false,
          :device => "eth1",
          :driver => "e1000e"
        }]        
      end
    end
  end
  
  cluster :parapide do |cluster_uid|
    model "SUN FIRE X2270"
    created_at Time.parse("2010-01-25").httpdate
    
    25.times do |i|
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
          :version => "X5570",
          :clock_speed => 2.93.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => nil
        })
        main_memory({
          :ram_size => 24.GiB,
          :virtual_size => nil
        })
        operating_system({
          :name => "Debian",
          :release => "5.0",
          :version => nil,
          :kernel => "2.6.26"
        })
        storage_devices [{
          :interface => 'SATA',
          :size => 500.GB,
          :driver => "ahci"
        }]
        network_adapters [{
          :interface => 'Ethernet',
          :rate => 1.G,
          :enabled => true,
          :mountable => true,
          :mounted => true,
          :device => "eth0",
          :driver => "igb",
          :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
          :switch => "c6509-grid"
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :enabled => false,
          :mountable => false,
          :mounted => false,
          :device => "eth1",
          :driver => "igb"
        },
        {
          :interface => 'Infiniband',
          :rate => 10.G,
          :enabled => true,
          :mountable => true,
          :mounted => true,
          :device => "ib0",
          :driver => "mlx4_core",
          :vendor => "Mellanox",
          :version => "MT25418",
          :network_address => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
          :ip => dns_lookup("#{node_uid}-ib0.#{site_uid}.grid5000.fr")
        }]
      end
    end
    
  end
  
end
