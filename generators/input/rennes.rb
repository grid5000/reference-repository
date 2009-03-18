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
  %w{sid-x64-base-1.0}.each do |env_id|
    environment env_id, :refer_to => "grid5000/environments/#{env_id}"
  end
  
  cluster :paravent do |cluster_uid|
    model "HP ProLiant DL145G2"
    created_at nil
    99.times do |i|
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
          :clock_speed => 2.giga,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => nil          
        })
        main_memory({
          :ram_size => 2.GB(true), # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SATA', :size => 80.GB(false), :driver => "sata_nv"}
          ]
        network_adapters [
          {:interface => 'InfiniBand 10G', :rate => 10.giga, 
            :switch => "c6509-grid", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"), 
            :vendor => "InfiniHost", :version => "MT23108", :enabled => true},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => false}
          ]        
      end
    end
  end

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
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SATA', :size => 300.GB(false), :driver => "megaraid_sas", :raid => "0"},
          {:interface => 'SATA', :size => 300.GB(false), :driver => "megaraid_sas", :raid => "0"}
          ]
        network_adapters [
          {:interface => 'Myri-10G', :rate => 10.giga, 
            :switch => "c6509-grid", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"), 
            :vendor => 'Myrinet', :version => "10G-PCIE-8A-C", :enabled => true},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => false}
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
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SATA', :size => 160.GB(false), :driver => "mptsas"}
          ]
        network_adapters [
            {:interface => 'Myri-10G', :rate => 10.giga, 
              :switch => "c6509-grid", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"), 
              :vendor => 'Myrinet', :version => "10G-PCIE-8A-C", :enabled => true},
            {:interface => 'Ethernet', :rate => 1.giga, :enabled => true},
            {:interface => 'Ethernet', :rate => 1.giga, :enabled => false}
          ]        
      end
    end
  end
end