site :bordeaux do |site_uid|
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
  ( %w{sid-x64-base-1.0 sid-x64-base-1.1 sid-x64-nfs-1.0 sid-x64-nfs-1.1 sid-x64-big-1.1} + 
    %w{etch-x64-base-1.0 etch-x64-base-1.1 etch-x64-nfs-1.0 etch-x64-nfs-1.1 etch-x64-big-1.0 etch-x64-big-1.1} +
    %w{lenny-x64-base-0.9 lenny-x64-nfs-0.9 lenny-x64-big-0.9}  ).each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}
  
  cluster :bordemer do |cluster_uid|
    model "IBM eServer 325"
    created_at nil
    misc "Motherboard Bios Version 1.33;IPMI version 1.5: Firware version 1.46"
    48.times do |i|
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
          {:interface => 'Myri-2000', :rate => 2.giga, 
            :switch => "sbdm", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :vendor => 'Myrinet', :version => "M3F-PCIXD-2", :enabled => true},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :driver => "tg3"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => false, :driver => "tg3"}
          ]
      end
    end
  end # cluster bordemer
  
  cluster :bordeplage do |cluster_uid|
    model "Dell PowerEdge 1855"
    created_at nil
    misc "Motherboard Bios version: A03 (05/12/2005);IPMI version 1.5: Firware revision 1.6"
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
          {:interface => 'InfiniBand', :rate => 10.giga, 
            :switch => "sbdp", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :vendor => 'InfiniHost', :version => "MT25208", :enabled => true},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :driver => "e1000"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => false, :driver => "e1000"}
          ]
      end
    end
  end # cluster bordeplage
  
  cluster :bordereau do |cluster_uid|
    model "IBM System x3455"
    created_at Time.parse("2007-10-01 12:00 GMT").httpdate
    misc "IPMI 2.0"
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
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, 
            :switch => nil, :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :driver => "tg3", :vendor => "Broadcom", :version => "BCM5704"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :driver => "tg3", :vendor => "Broadcom", :version => "BCM5704"}
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
          {:interface => 'Myri-10G', :rate => 10.giga, 
            :switch => nil, :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :vendor => 'Myrinet', :version => "10G-PCIE-8A-C", :enabled => true},
          {:interface => 'InfiniBand', :rate => 10.giga, :vendor => 'InfiniHost', :version => "MT25408", :enabled => true},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :driver => "e1000"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => false, :driver => "e1000"}
          ]
      end
    end
  end # cluster borderline
end