site :sophia do |site_uid|
  name "Sophia-Antipolis"
  location "Sophia-Antipolis, France"
  web
  description ""
  latitude 43.6161
  longitude 7.0678
  email_contact "sophia-staff@lists.grid5000.fr"
  sys_admin_contact "sophia-staff@lists.grid5000.fr"
  security_contact "sophia-staff@lists.grid5000.fr"
  user_support_contact "sophia-staff@lists.grid5000.fr"
  ( %w{sid-x64-base-1.0 sid-x64-base-1.1 sid-x64-nfs-1.0 sid-x64-nfs-1.1 sid-x64-big-1.1} + 
    %w{etch-x64-base-1.0 etch-x64-base-1.1 etch-x64-nfs-1.0 etch-x64-nfs-1.1 etch-x64-big-1.0 etch-x64-big-1.1} +
    %w{lenny-x64-base-0.9 lenny-x64-nfs-0.9 lenny-x64-big-0.9}  ).each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}
  compilation_server true
  
  cluster :azur do |cluster_uid|
    model "IBM eServer 325"
    created_at Time.parse("2005-02-18").httpdate
    72.times do |i|
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
          :version => "246",
          :clock_speed => 2.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 1.MiB          
        })
        main_memory({
          :ram_size => 2.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'IDE', :size => 80.GB, :driver => "amd74xx"}
          ]
        network_adapters [
          {:interface => 'Myri-2000', :rate => 2.G, :enabled => true, 
            :switch => "cisco1", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :vendor => 'Myrinet', :version => "M3F-PCIXF-2"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, :driver => "tg3"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => false, :driver => "tg3"}
          ]   
      end
    end
  end
    
  cluster :helios do |cluster_uid|
    model "Sun Fire X4100"
    created_at Time.parse("2006-06-02").httpdate
    56.times do |i|
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
          :version => "275",
          :clock_speed => 2.2.G,
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
          {:interface => 'SAS', :size => 73.GB, :driver => "mptsas", :raid => "0"},
          {:interface => 'SAS', :size => 73.GB, :driver => "mptsas", :raid => "0"}
          ]
        network_adapters [
          {:interface => 'Myri-2000', :rate => 2.G, :enabled => true, 
            :switch => "edgeiron48gs", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :vendor => 'Myrinet', :version => "M3F-PCIXF-2"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, :driver => "e1000"},  
          {:interface => 'Ethernet', :rate => 1.G, :enabled => false, :driver => "e1000"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => false, :driver => "e1000"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => false, :driver => "e1000"}
          ]          
      end
    end
  end
    
  cluster :sol do |cluster_uid|
    model "Sun Fire X2200 M2"
    created_at Time.parse("2007-02-23").httpdate
    50.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => "amd-v"})
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
          {:interface => 'SATA', :size => 250.GB, :driver => "sata_nv"}
          ]
        network_adapters [
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, 
            :switch => "fastiron", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :vendor => "NVIDIA", :version => "MCP55 Pro"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, :vendor => "NVIDIA", :version => "MCP55 Pro"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => false, :vendor => "Broadcom", :version => "BCM5715c"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => false, :vendor => "Broadcom", :version => "BCM5715c"}            
          ]          
      end
    end
  end
end
