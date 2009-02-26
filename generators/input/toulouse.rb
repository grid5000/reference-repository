site :toulouse do
  name "Toulouse"
  location "Toulouse, France"
  web
  description ""
  latitude
  longitude
  email_contact
  sys_admin_contact
  security_contact
  user_support_contact
  %w{sid-x64-base-1.0}.each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}

  cluster :violette do
    model "Sun Fire V20z"
    date_of_arrival Time.parse("2004-09-01").to_i
    
    57.times do |i|
      node "violette-#{i+1}" do
        architecture({
          :smp_size => 2, 
          :smt_size => 2,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "AMD",
          :model => "AMD Opteron",
          :version => "248",
          :clock_speed => 2.2.giga,
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
          {:interface => 'SCSI', :size => 73.GB(false), :driver => "mptspi"}
          ]
        network_adapters [
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :driver => "tg3"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => false, :driver => "tg3"}
          ]  
      end      
    end
  end
  
  cluster :pastel do
    model "Sun Fire X2200 M2"
    date_of_arrival Time.parse("2007-11-29").to_i
    
    80.times do |i|
      node "pastel-#{i+1}" do
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
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 1.MB
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
          {:interface => 'SATA', :size => 250.GB(false), :driver => "sata_nv"}
          ]
        network_adapters [
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :vendor => "NVIDIA", :version => "MCP55 Pro", :driver => "forcedeth"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => false, :vendor => "NVIDIA", :version => "MCP55 Pro", :driver => "forcedeth"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => false, :vendor => "Broadcom", :version => "BCM5715c", :driver => "tg3"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => false, :vendor => "Broadcom", :version => "BCM5715c", :driver => "tg3"}
          ]  
      end      
    end
  end
  
end