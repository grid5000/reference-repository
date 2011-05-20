def get_macaddr(node,interf)
return ""
end

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
  ( %w{etch-x64-base-1.0 etch-x64-base-1.1 etch-x64-nfs-1.0 etch-x64-nfs-1.1 etch-x64-big-1.0 etch-x64-big-1.1 etch-x64-base-2.0 etch-x64-nfs-2.0 etch-x64-big-2.0} +
    %w{lenny-x64-base-0.9 lenny-x64-nfs-0.9 lenny-x64-big-0.9 lenny-x64-base-1.0 lenny-x64-nfs-1.0 lenny-x64-big-1.0 lenny-x64-base-2.0 lenny-x64-nfs-2.0 lenny-x64-big-2.0} +
    %w{lenny-x64-base-2.3 lenny-x64-big-2.3 lenny-x64-min-0.8 lenny-x64-nfs-2.3 lenny-x64-xen-2.3} +
    %w{squeeze-x64-base-0.8 squeeze-x64-big-0.8 squeeze-x64-min-0.8 squeeze-x64-nfs-0.8 squeeze-x64-xen-0.8}  ).each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}
  
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
          {:interface => 'InfiniBand', :rate => 10.G, 
            :network_address => "#{node_uid}-ib0.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-ib0.#{site_uid}.grid5000.fr"),
            :vendor => 'Mellanox', :version => "InfiniHost MT25208", 
            :enabled => true, :mountable => true, :mounted => true, :driver => "ib_mthca", :management => false, :device => "ib0",
            :mac => get_macaddr("#{node_uid}.#{site_uid}.grid5000.fr","ib0")},
          {:interface => 'Ethernet', :rate => 1.G, 
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"), 
            :vendor => "Intel", :version => "82546GB Gigabit Ethernet Controller",
            :enabled => true, :mounted => true, :mountable => true, :driver => "e1000", :management => false, :device => "eth0",
            :mac => get_macaddr("#{node_uid}.#{site_uid}.grid5000.fr","eth0")},
          {:interface => 'Ethernet', :rate => 1.G,
            :network_address => "#{node_uid}-eth1.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-eth1.#{site_uid}.grid5000.fr"),
            :vendor => "Intel", :version => "82546GB Gigabit Ethernet Controller",
            :enabled => true, :mounted => false, :mountable => true, :driver => "e1000", :management => false, :device => "eth1",
            :mac => get_macaddr("#{node_uid}.#{site_uid}.grid5000.fr","eth1")}
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
          {:interface => 'Ethernet', :rate => 1.G,
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
	    :vendor => "Broadcom", :version => "BCM5704",
            :enabled => true, :mounted => true, :mountable => true, :driver => "tg3", :management => false, :device => "eth0",
	    :mac => get_macaddr("#{node_uid}.#{site_uid}.grid5000.fr","eth0")},
          {:interface => 'Ethernet', :rate => 1.G,
            :network_address => "#{node_uid}-eth1.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-eth1.#{site_uid}.grid5000.fr"),
	    :vendor => "Broadcom", :version => "BCM5704",
            :enabled => true, :mounted => false, :mountable => true, :driver => "tg3", :management => false, :device => "eth1",
	    :mac => get_macaddr("#{node_uid}.#{site_uid}.grid5000.fr","eth1")}

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
          {:interface => 'Ethernet', :rate => 1.G, 
	    :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"), 
	    :vendor => "Broadcom", :version => "NetXtreme II BCM5708",
	    :enabled => true, :mounted => true, :mountable => true, :driver => "bnx2", :management => false, :device => "eth0",
	    :mac => get_macaddr("#{node_uid}.#{site_uid}.grid5000.fr","eth0")},
          {:interface => 'Ethernet', :rate => 1.G,
            :network_address => "#{node_uid}-eth1.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-eth1.#{site_uid}.grid5000.fr"),
	    :vendor => "Broadcom", :version => "NetXtreme II BCM5708",
            :enabled => true, :mounted => false, :mountable => true, :driver => "bnx2", :management => false, :device => "eth1",
	    :mac => get_macaddr("#{node_uid}.#{site_uid}.grid5000.fr","eth1")},
	  {:interface => 'InfiniBand', :rate => 10.G, 
	    :network_address => "#{node_uid}-ib0.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-ib0.#{site_uid}.grid5000.fr"),
	    :vendor => 'Mellanox', :version => "InfiniHost MT25208", 
	    :enabled => true, :mountable => true, :mounted => true, :driver => "ib_mthca", :management => false, :device => "ib0",
	    :mac => get_macaddr("#{node_uid}.#{site_uid}.grid5000.fr","ib0")},
	  {:interface => 'Myrinet', :rate => 10.G, 
	     :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-myri0.#{site_uid}.grid5000.fr"),
	     :vendor => 'Myrinet', :version => "10G-PCIE-8A-C",
	     :enabled => true, :mountable => true, :mounted => true, :driver => "ib_mthca", :management => false, :device => "myri0",
	     :mac => get_macaddr("#{node_uid}.#{site_uid}.grid5000.fr","myri0")}]
	  end 
	end 
  end # cluster borderline
end
