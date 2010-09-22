site :lille do |site_uid|
  name "Lille"
  location "Lille, France"
  web
  description ""
  latitude 50.6500
  longitude 3.0833
  email_contact
  sys_admin_contact
  security_contact
  user_support_contact
  ( %w{sid-x64-base-1.0 sid-x64-base-1.1 sid-x64-nfs-1.0 sid-x64-nfs-1.1 sid-x64-big-1.1} + 
    %w{etch-x64-base-1.0 etch-x64-base-1.1 etch-x64-nfs-1.0 etch-x64-nfs-1.1 etch-x64-big-1.0 etch-x64-big-1.1 etch-x64-xen-1.0 etch-x64-base-2.0 etch-x64-nfs-2.0 etch-x64-big-2.0} +
    %w{lenny-x64-base-0.9 lenny-x64-nfs-0.9 lenny-x64-big-0.9 lenny-x64-base-1.0 lenny-x64-nfs-1.0 lenny-x64-big-1.0 lenny-x64-xen-1.0 lenny-x64-base-2.0 lenny-x64-nfs-2.0 lenny-x64-big-2.0}  ).each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}
  
  cluster :chuque do |cluster_uid|
    model "IBM eServer 326"
    created_at nil
    53.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => false})
        architecture({
          :smp_size => 2, 
          :smt_size => 2,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "AMD",
          :model => "AMD Opteron",
          :version => "248",
          :clock_speed => 2.2.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 1.MiB
        })
        main_memory({
          :ram_size => 4.GiB,
          :virtual_size => nil
        })
        operating_system({
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SATA', :size => 80.GB, :driver => "sata_sil"}
          ]
        network_adapters [
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, :management => true, 
            :switch => "gw", :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-eth0.#{site_uid}.grid5000.fr"),
            :driver => "tg3", :mountable => true, :mounted => true, :device => "eth0"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, :management => false,
            :switch => "gw", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :driver => "tg3", :mountable => true, :mounted => true, :device => "eth1"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, :management => true,
            :switch => "gw", :network_address => "#{node_uid}-rsa.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-rsa.#{site_uid}.grid5000.fr"),
            :driver => "tg3",:mountable => false}
          ]  
      end
    end
  end # cluster chuque
  cluster :chti do |cluster_uid|
    model "IBM eServer 326m"
    created_at nil
    
    20.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => false})
        architecture({
          :smp_size => 2, 
          :smt_size => 2,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "AMD",
          :model => "AMD Opteron",
          :version => "252",
          :clock_speed => 2.6.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 1.MiB
        })
        main_memory({
          :ram_size => 4.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SATA', :size => 80.GB, :driver => "sata_svw"}
          ]
        network_adapters [
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, :management => true, 
            :switch => "gw", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-eth0.#{site_uid}.grid5000.fr"),
            :driver => "tg3", :mountable => true, :mounted => true, :device => "eth0"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, :management => false, 
            :switch => "gw", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :driver => "tg3", :switch_port => lookup('lille', "#{node_uid}", 'switch_port'), :mountable => true, :mounted => true, :device => "eth1"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, :management => true,
            :switch => "gw", :network_address => "#{node_uid}-rsa.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-rsa.#{site_uid}.grid5000.fr"),
            :driver => "tg3",:mountable => false},
          {:interface => 'Myrinet', :rate => 10.G, :enabled => true, :management => true,
            :switch => nil, :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-myri0.#{site_uid}.grid5000.fr"),
            :vendor => "Myrinet", :version => "10G-PCIE-8A-C", :mountable => true, :mounted => true, :device => "myri0"}
          ]        
      end
    end
  end # cluster chti   
  
  cluster :chicon do |cluster_uid|
    model "IBM eServer 326m"
    created_at nil
    26.times do |i|
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
          :version => "285",
          :clock_speed => 2.6.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 1.MiB
        })
        main_memory({
          :ram_size => 4.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SATA', :size => 80.GB, :driver => "sata_svw"}
          ]
        network_adapters [
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, :management => true, 
            :switch => "gw", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-eth0.#{site_uid}.grid5000.fr"),
            :driver => "tg3", :mountable => true, :mounted => true, :device => "eth0"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, :management => false, 
            :switch => "gw", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :driver => "tg3", :switch_port => lookup('lille', "#{node_uid}", 'switch_port'), :mountable => true, :mounted => true, :device => "eth1"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, :management => true,
            :switch => "gw", :network_address => "#{node_uid}-rsa.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-rsa.#{site_uid}.grid5000.fr"),
            :driver => "tg3",:mountable => false},
          {:interface => 'Myrinet', :rate => 10.G, :enabled => true, :management => true,
            :switch => nil, :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-myri0.#{site_uid}.grid5000.fr"),
            :vendor => "Myrinet", :version => "10G-PCIE-8A-C", :mountable => true, :mounted => true, :device => "myri0"}
          ]        
      end
    end
  end # cluster chicon
  
  cluster :chinqchint do |cluster_uid|
    model "Altix Xe 310"
    created_at nil
    46.times do |i|
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
          :version => "E5440 QC",
          :clock_speed => 2.83.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 4.MiB
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
          {:interface => 'SATA II', :size => 250.GB, :driver => "ahci"}
          ]
        network_adapters [
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, :management => true, 
            :switch => "gw", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-eth0.#{site_uid}.grid5000.fr"),
            :driver => "e1000", :mountable => true, :mounted => true, :device => "eth0"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, :management => false, 
            :switch => "gw", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :driver => "e1000", :switch_port => lookup('lille', "#{node_uid}", 'switch_port'), :mountable => true, :mounted => true, :device => "eth1"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, :management => true,
            :switch => "gw", :network_address => "#{node_uid}-ipmi.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-ipmi.#{site_uid}.grid5000.fr"),
            :driver => "e1000",:mountable => false},
          {:interface => 'Myrinet', :rate => 10.G, :enabled => true, :management => true,
            :switch => nil, :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-myri0.#{site_uid}.grid5000.fr"),
            :vendor => "Myrinet", :version => "10G-PCIE-8A-C", :mountable => true, :mounted => true, :device => "myri0"}
          ]
      end
    end
  end
  
end
