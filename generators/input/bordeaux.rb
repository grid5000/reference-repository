site :bordeaux do
  name "Bordeaux"
  location "Bordeaux, France"
  web
  description ""
  latitude
  longitude
  email_contact
  sys_admin_contact
  security_contact
  user_support_contact
  %w{sid-x64-base-1.0}.each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}
  
  cluster :bordemer do
    model "IBM eServer 325"
    date_of_arrival nil
    misc "Motherboard Bios Version 1.33;IPMI version 1.5: Firware version 1.46"
    48.times do |i|
      node "bordemer-#{i+1}" do
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
          :cache_l2 => 1.MB
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
        network_adapters [
          {:interface => 'Myri-2000', :rate => 2.giga, :vendor => 'Myrinet', :version => "M3F-PCIXD-2", :enabled => true},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :driver => "tg3"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => false, :driver => "tg3"}
          ]
      end
    end
  end # cluster bordemer
  
  cluster :bordeplage do
    model "Dell PowerEdge 1855"
    date_of_arrival nil
    misc "Motherboard Bios version: A03 (05/12/2005);IPMI version 1.5: Firware revision 1.6"
    51.times do |i|
      node "bordeplage-#{i+1}" do
        architecture({
          :smp_size => 2, 
          :smt_size => 2,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "Intel",
          :model => "Intel Xeon",
          :version => "EM64T",
          :clock_speed => 3.giga,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 1.MB
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
          {:interface => 'SCSI', :size => 70.GB(false), :driver => "mptspi"}
          ]
        network_adapters [
          {:interface => 'InfiniBand', :rate => 10.giga, :vendor => 'InfiniHost', :version => "MT25208", :enabled => true},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :driver => "e1000"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => false, :driver => "e1000"}
          ]
      end
    end
  end # cluster bordeplage
  
  cluster :bordereau do
    model "IBM System x3455"
    date_of_arrival Time.parse("2007-10-01 12:00 GMT").to_i
    misc "IPMI 2.0"
    93.times do |i|
      node "bordereau-#{i+1}" do
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
          :cache_l2 => 2.MB
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
          {:interface => 'SATA', :size => 80.GB(false), :driver => "sata_svw", :vendor => "Hitachi", :version => "HDS72168"}
          ]
        network_adapters [
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :driver => "tg3", :vendor => "Broadcom", :version => "BCM5704"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :driver => "tg3", :vendor => "Broadcom", :version => "BCM5704"}
          ]
      end
    end
  end # cluster bordereau
  
  cluster :borderline do
    model "IBM System x3755"
    date_of_arrival Time.parse("2007-10-01 12:00 GMT").to_i
    misc "IPMI 2.0"
    10.times do |i|
      node "borderline-#{i+1}" do
        architecture({
          :smp_size => 4, 
          :smt_size => 8,
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
          :cache_l2 => 2.MB
        })
        main_memory({
          :ram_size => 32.GB(true), # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SAS', :size => 600.GB(false), :driver => nil}
          ]
        network_adapters [
          {:interface => 'Myri-10G', :rate => 10.giga, :vendor => 'Myrinet', :version => "10G-PCIE-8A-C", :enabled => true},
          {:interface => 'InfiniBand', :rate => 10.giga, :vendor => 'InfiniHost', :version => "MT25408", :enabled => true},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :driver => "e1000"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => false, :driver => "e1000"}
          ]
      end
    end
  end # cluster borderline
end