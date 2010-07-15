site :bordeaux do |site_uid|
  name "Bordeaux"
  location "Bordeaux, France"
  web "http://www.grid5000.fr/mediawiki/index.php/Bordeaux:Home"
  description "Grid5000 Bordeaux site"
  latitude 44.833333
  longitude -0.566667
  email_contact "bordeaux-staff@lists.grid5000.fr"
  sys_admin_contact "bordeaux-staff@lists.grid5000.fr"
  security_contact "bordeaux-staff@lists.grid5000.fr"
  user_support_contact "bordeaux-staff@lists.grid5000.fr"
  ( %w{sid-x64-base-1.0 sid-x64-base-1.1 sid-x64-nfs-1.0 sid-x64-nfs-1.1 sid-x64-big-1.1} + 
    %w{etch-x64-base-1.0 etch-x64-base-1.1 etch-x64-nfs-1.0 etch-x64-nfs-1.1 etch-x64-big-1.0 etch-x64-big-1.1 etch-x64-base-2.0 etch-x64-nfs-2.0 etch-x64-big-2.0} +
    %w{lenny-x64-base-0.9 lenny-x64-nfs-0.9 lenny-x64-big-0.9 lenny-x64-base-1.0 lenny-x64-nfs-1.0 lenny-x64-big-1.0 lenny-x64-base-2.0 lenny-x64-nfs-2.0 lenny-x64-big-2.0}  ).each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}
  
  cluster :bordeplage do |cluster_uid|
    model "Dell PowerEdge 1855"
    created_at nil
    misc "Motherboard Bios version: A05 ;IPMI version 1.5: Firware revision 1.6"
    51.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => false})
        architecture({
          :smp_size => 2, 
          :smt_size => 2,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "Intel",
          :model => "Intel Xeon",
          :version => "EM64T",
          :clock_speed => 3.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => 16.KiB,
          :cache_l2 => 1.MiB
        })
        main_memory({
          :ram_size => 2.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
	  :kadeploy_name => "debian-x64-5-prod",    
          :kadeploy_version => "1",       
          :name => "Debian Lenny",
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SCSI', :size => 70.GB, :driver => "mptspi"}
          ]
        network_adapters [
          {:interface => 'InfiniBand SDR', :rate => 10.G, 
            :switch => "sbdp", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-ib0.#{site_uid}.grid5000.fr"),
            :vendor => 'Mellanox', :version => "InfiniHost MT25208", :enabled => true},
          {:interface => 'Ethernet', :rate => 1.G, 
	    :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"), 
	    :enabled => true, :driver => "e1000"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => false, :driver => "e1000"}
          ]
      end
    end
  end # cluster bordeplage
  
  cluster :bordereau do |cluster_uid|
    model "IBM System x3455"
    created_at Time.parse("2007-10-01 12:00 GMT").httpdate
    misc "IPMI 2.0, BIOS Version 1.32"
    93.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => false})
        architecture({
          :smp_size => 2, 
          :smt_size => 4,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "AMD",
          :model => "AMD Opteron",
          :version => "2218",
          :clock_speed => 2.6.G,
          :instruction_set => "x86-64",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => 64.KiB,
          :cache_l1d => 64.KiB,
          :cache_l2 => 1.MiB
        })
        main_memory({
          :ram_size => 4.GiB,
          :virtual_size => nil
        })
        operating_system({
	  :kadeploy_name => "debian-x64-5-prod",
          :kadeploy_version => "1",
          :name => "Debian Lenny",
          :release => nil,
          :version => nil        
	})
        storage_devices [
          {:interface => 'SATA', :size => 80.GB, :driver => "sata_svw", :vendor => "Hitachi", :version => "HDS72168"}
          ]
        network_adapters [
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, 
            :switch => nil, :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :driver => "tg3", :vendor => "Broadcom", :version => "BCM5704"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, :driver => "tg3", :vendor => "Broadcom", :version => "BCM5704"}
          ]
      end
    end
  end # cluster bordereau
  
  cluster :borderline do |cluster_uid|
    model "IBM System x3755"
    created_at Time.parse("2007-10-01 12:00 GMT").httpdate
    misc "IPMI 2.0"
    10.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => false, :besteffort => true, :virtual => "amd-v"})
        architecture({
          :smp_size => 4, 
          :smt_size => 8,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "AMD",
          :model => "AMD Opteron",
          :version => "8218",
          :clock_speed => 2.6.G,
          :instruction_set => "x86-64",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => 64.KiB,
          :cache_l1d => 64.KiB,
          :cache_l2 => 2.MiB
	})
        main_memory({
          :ram_size => 32.GiB,
          :virtual_size => nil
        })
        operating_system({
          :name => "ClusterVision OS",
          :release => "Boron",
          :version => "3.1"
        })
        storage_devices [
          {:interface => 'SAS', :size => 600.GB, :driver => nil}
          ]
        network_adapters [
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, :driver => "e1000"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => false, :driver => "e1000"}
          ]
#some cards have been swapped between hosts - refer to bug 2681 for explanations
	  if i == 2 or i == 3
	  network_adapters [
		{:interface => 'InfiniBand SDR', :rate => 10.G, :vendor => 'Mellanox', :version => "InfiniHost MT25408", :enabled => true},
		  {:interface => 'InfiniBand SDR', :rate => 10.G, :vendor => 'Mellanox', :version => "InfiniHost MT25408", :enabled => true}]
	  elsif i == 0 or i == 1
	  network_adapters [
		  {:interface => 'Myrinet 10G', :rate => 10.G, 
		    :switch => nil, :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
		    :vendor => 'Myrinet', :version => "10G-PCIE-8A-C", :enabled => true},
		  {:interface => 'Myrinet 10G', :rate => 10.G, 
		    :switch => nil, :network_address => "#{cluster_uid}-#{(i-2)-(i-3)*2}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{cluster_uid}-#{(i-2)-(i-3)*2}.#{site_uid}.grid5000.fr"),
		    :vendor => 'Myrinet', :version => "10G-PCIE-8A-C", :enabled => true}]
	    else
	    network_adapters [
		{:interface => 'InfiniBand SDR', :rate => 10.G, :vendor => 'Mellanox', :version => "InfiniHost MT25408", :enabled => true},
		  {:interface => 'Myrinet 10G', :rate => 10.G, 
		    :switch => nil, :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
		    :vendor => 'Myrinet', :version => "10G-PCIE-8A-C", :enabled => true}]
	    end
      end
    end
  end # cluster borderline
end
