site :sophia do
  name "Sophia-Antipolis"
  location "Sophia-Antipolis, France"
  web
  description ""
  latitude
  longitude
  email_contact
  sys_admin_contact
  security_contact
  user_support_contact
  %w{sid-x64-base-1.0}.each do |env_id|
    environment env_id, :refer_to => "grid5000/environments/#{env_id}"
  end
  
  cluster :azur do
    model "IBM eServer 325"
    created_at Time.parse("2005-02-18").to_i
    72.times do |i|
      node "azur-#{i+1}" do
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
          :cache_l1 => 1.MB,
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
          {:interface => 'IDE', :size => 80.GB(false), :driver => "amd74xx"}
          ]
        network_adapters []        
      end
    end
  end
    
  cluster :helios do
    model "Sun Fire X4100"
    created_at Time.parse("2006-06-02").to_i
    56.times do |i|
      node "helios-#{i+1}" do
        architecture({
          :smp_size => 2,
          :smt_size => 4,
          :platform_type => "x86_64"
        })
        processor({
          :vendor => "AMD",
          :model => "AMD Opteron",
          :version => "275",
          :clock_speed => 2.2.giga,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => 1.MB,
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
          {:interface => 'SAS', :size => 73.GB(false), :driver => "mptsas", :raid => "0"},
          {:interface => 'SAS', :size => 73.GB(false), :driver => "mptsas", :raid => "0"}
          ]
        network_adapters []          
      end
    end
  end
    
  cluster :sol do
    model "Sun Fire X2200 M2"
    created_at Time.parse("2007-02-23").to_i
    50.times do |i|
      node "sol-#{i+1}" do
        architecture({
          :smp_size => 2,
          :smt_size => 4,
          :platform_type => "x86_64"
        })
        processor({
          :vendor => "AMD",
          :model => "AMD Opteron",
          :version => "2218",
          :clock_speed => 2.6.giga,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => 1.MB,
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
          {:interface => 'SATA', :size => 250.GB(false), :driver => "sata_nv"}
          ]
        network_adapters [
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :vendor => "NVIDIA", :version => "MCP55 Pro"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :vendor => "NVIDIA", :version => "MCP55 Pro"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => false, :vendor => "Broadcom", :version => "BCM5715c"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => false, :vendor => "Broadcom", :version => "BCM5715c"}            
          ]          
      end
    end
  end
  #   
  # cluster :storage do
  #   model "Sun X4100"
  #   node "storage-1" do
  #     architecture({
  #       :smp_size => 2,
  #       :smt_size => 2,
  #       :platform_type => ""
  #     })
  #     processor({
  #       :vendor => "AMD",
  #       :model => "AMD Opteron",
  #       :version => "275",
  #       :clock_speed => 2.2.giga,
  #       :instruction_set => "",
  #       :other_description => "",
  #       :cache_l1 => nil,
  #       :cache_l1i => nil,
  #       :cache_l1d => nil,
  #       :cache_l2 => nil          
  #     })
  #     main_memory({
  #       :ram_size => 4.GB(true), # bytes
  #       :virtual_size => nil
  #     })
  #     operating_system({
  #       :name => nil,
  #       :release => nil,
  #       :version => nil
  #     })
  #     storage_devices [
  #       {:interface => 'SAS', :size => 73.GB(false), :rpm => 10_000, :raid => "1 'Mirroring'"},
  #       {:interface => 'SATA II', :size => 2.TB(false), :raid => "5", :name => "Sun StorEdge 3511 FC Array"}
  #       ]
  #     network_adapters [
  #       {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :vendor => "Intel", :version => "e1000"},
  #       {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :vendor => "Intel", :version => "e1000"},
  #       {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :vendor => "Intel", :version => "e1000"},
  #       {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :vendor => "Intel", :version => "e1000"},
  #       {:interface => 'Fibre Channel', :rate => 2.giga, :enabled => true, :vendor => "QLogic", :version => "QLA2342"}           
  #       ]        
  #   end
  # end
end