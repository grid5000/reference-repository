site :rennes do |site_uid|
  name "Rennes"
  location "Rennes, France"
  web "http://www.irisa.fr"
  description ""
  latitude 48.114722
  longitude -1.679444
  email_contact
  sys_admin_contact
  security_contact
  user_support_contact
  ( %w{sid-x64-base-1.0 sid-x64-base-1.1 sid-x64-nfs-1.0 sid-x64-nfs-1.1 sid-x64-big-1.1} + 
    %w{etch-x64-base-1.0 etch-x64-base-1.1 etch-x64-nfs-1.0 etch-x64-nfs-1.1 etch-x64-big-1.0 etch-x64-big-1.1} +
    %w{lenny-x64-base-0.9 lenny-x64-nfs-0.9 lenny-x64-big-0.9}  ).each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}
  
  
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
          :clock_speed => 2.33.giga,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => nil          
        })
        main_memory({
          :ram_size => 8.GB(true), # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => "Ubuntu",
          :release => "6.10",
          :version => nil,
          :kernel => "2.6.19.1"
        })
        storage_devices [
          {:interface => 'SATA', :size => 300.GB(false), :driver => "megaraid_sas", :raid => "0"},
          {:interface => 'SATA', :size => 300.GB(false), :driver => "megaraid_sas", :raid => "0"}
          ]
        network_adapters [
          {:interface => 'Myri-10G', :rate => 10.giga, 
            :switch => "c6509-grid", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"), 
            :vendor => 'Myrinet', :version => "10G-PCIE-8A-C", :enabled => true},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :driver => "bnx2"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => false, :driver => "bnx2"}
          ]
      end
    end
  end
  
  cluster :paraquad do |cluster_uid|
    model "Dell PowerEdge 1950"
    created_at Time.parse("2006-12-01").httpdate
    
    64.times do |i|
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
          :clock_speed => 2.33.giga,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => nil
        })
        main_memory({
          :ram_size => 4.GB(true), # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => "Ubuntu",
          :release => "6.10",
          :version => nil,
          :kernel => "2.6.19.1"
        })
        storage_devices [
          {:interface => 'SATA', :size => 160.GB(false), :driver => "mptsas"}
          ]
        network_adapters [
            {:interface => 'Myri-10G', :rate => 10.giga, 
              :switch => "c6509-grid", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"), 
              :vendor => 'Myrinet', :version => "10G-PCIE-8A-C", :enabled => true},
            {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :driver => "bnx2"},
            {:interface => 'Ethernet', :rate => 1.giga, :enabled => false, :driver => "bnx2"}
          ]        
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
          :clock_speed => 2.5.giga,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => nil
        })
        main_memory({
          :ram_size => 32.GB(true), # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => "Ubuntu",
          :release => "6.10",
          :version => nil,
          :kernel => "2.6.28"
        })
        storage_devices [
          {:interface => 'SATA', :size => 160.GB(false), :driver => "ata_piix"}
          ]
        network_adapters [
            {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :driver => "e1000e"},
            {:interface => 'Ethernet', :rate => 1.giga, :enabled => false, :driver => "e1000e"}
          ]        
      end
    end
  end
  
end