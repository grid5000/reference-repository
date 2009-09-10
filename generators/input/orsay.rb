site :orsay do |site_uid|
  name "Orsay"
  location "Orsay, France"
  web
  description ""
  latitude 48.7000
  longitude 2.2000
  email_contact
  sys_admin_contact
  security_contact
  user_support_contact
  ( %w{sid-x64-base-1.0 sid-x64-base-1.1 sid-x64-nfs-1.0 sid-x64-nfs-1.1 sid-x64-big-1.1} + 
    %w{etch-x64-base-1.0 etch-x64-base-1.1 etch-x64-nfs-1.0 etch-x64-nfs-1.1 etch-x64-big-1.0 etch-x64-big-1.1 etch-x64-base-2.0 etch-x64-nfs-2.0 etch-x64-big-2.0} +
    %w{lenny-x64-base-0.9 lenny-x64-nfs-0.9 lenny-x64-big-0.9 lenny-x64-base-1.0 lenny-x64-nfs-1.0 lenny-x64-big-1.0 lenny-x64-base-2.0 lenny-x64-nfs-2.0 lenny-x64-big-2.0}  ).each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}

  cluster :netgdx do |cluster_uid|
    model "IBM eServer 326m"
    created_at nil
    misc "bios:1.28/bcm:1.20.17/bmc:1.10/rsaII:1.00"
    30.times do |i|
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
          {:interface => 'SATA', :size => 80.GB, :driver => nil}
          ]
        network_adapters [
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, 
            :switch => nil, :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :driver => nil},          
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true,
            :switch => nil, :network_address => "#{node_uid}-eth1.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-eth1.#{site_uid}.grid5000.fr"),
            :driver => nil},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true,
            :switch => nil, :network_address => "#{node_uid}-eth2.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-eth2.#{site_uid}.grid5000.fr"),
            :driver => nil}
          ]  
      end      
    end
  end # cluster net-gdx
  
  cluster :gdx do |cluster_uid|
    model "IBM eServer 326m"
    created_at nil
    misc "bios:1.28/bcm:1.20.17/bmc:1.10/rsaII:1.00"
    
    # WARN: 2 nodes are missing (gdx-311 and gdx-312) and won't appear in the reference
    (180+132-2).times do |i|
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
          {:interface => 'SATA', :size => 80.GB, :driver => nil}
          ]
        network_adapters [  
          {:interface => 'Myri-10G', :rate => 10.G, :enabled => true, 
            :switch => nil, :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :vendor => "Myrinet", :version => "10G-PCIE-8A-C"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => false}
          ]
      end        
    end
    
    # extension specifics, starting at node 181
    (132-2).times do |i|
      node "#{cluster_uid}-#{181+i}" do
        processor({
          :version => "250",
          :clock_speed => 2.4.G
        })
      end
    end
    
  end # cluster gdx
  
end
