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
        network_adapters [{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => nil,
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5704',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'tg3',
            :mounted => true,
            :device => "eth0",
            :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-eth0.#{site_uid}.grid5000.fr"),
            :switch => "gw"
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => nil,
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5704',
            :enabled => true,
            :management => false,
            :mountable => true,
            :mounted => true,
            :device => "eth1",
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :driver => "tg3",
            :switch => "gw"
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => nil,
            :vendor => nil,
            :version => nil,
            :enabled => true,
            :management => true,
            :mountable => false,
            :network_address => "#{node_uid}-rsa.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-rsa.#{site_uid}.grid5000.fr"),
            :switch => "gw"
          }]  
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
        network_adapters [{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => nil,
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5780',
            :enabled => true,
            :management => false, 
            :mountable => true,
            :driver => 'tg3',
            :mounted => true,
            :device => 'eth0',
            :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-eth0.#{site_uid}.grid5000.fr"),
            :switch => 'gw'
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => nil,
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5780',
            :enabled => true,
            :management => false, 
            :mountable => true,
            :driver => 'tg3',
            :mounted => true,
            :device => 'eth1',
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :switch => "gw",
            :switch_port => lookup('lille', "#{node_uid}", 'switch_port')
          },{
            :interface => 'Ethernet', 
            :rate => 1.G,
            :mac => nil,
            :vendor => nil,
            :version => nil,
            :enabled => true,
            :management => true,
            :mountable => false,
            :network_address => "#{node_uid}-rsa.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-rsa.#{site_uid}.grid5000.fr"),
            :switch => 'gw'
          },{
            :interface => 'Myrinet',
            :rate => 10.G,
            :mac => nil,
            :vendor => "Myricom",
            :version => "10G-PCIE-8A-C",
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'mx',
            :mounted => true, 
            :device => 'myri0',
            :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-myri0.#{site_uid}.grid5000.fr"),
            :switch => nil
          }]
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
        network_adapters [{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => nil,
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5780',
            :enabled => true,
            :management => false, 
            :mountable => true,
            :driver => 'tg3',
            :mounted => true,
            :device => 'eth0',
            :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-eth0.#{site_uid}.grid5000.fr"),
            :switch => 'gw'
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => nil,
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5780',
            :enabled => true,
            :management => false, 
            :mountable => true,
            :driver => 'tg3',
            :mounted => true,
            :device => 'eth1',
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :switch => 'gw',
            :switch_port => lookup('lille', "#{node_uid}", 'switch_port')
          },{
            :interface => 'Ethernet', 
            :rate => 1.G,
            :mac => nil,
            :vendor => nil,
            :version => nil,
            :enabled => true,
            :management => true,
            :mountable => false,
            :network_address => "#{node_uid}-rsa.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-rsa.#{site_uid}.grid5000.fr"),
            :switch => 'gw'
         },{
            :interface => 'Myrinet',
            :rate => 10.G,
            :mac => nil,
            :vendor => "Myricom",
            :version => "10G-PCIE-8A-C",
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'mx',
            :mounted => true, 
            :device => 'myri0',
            :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-myri0.#{site_uid}.grid5000.fr"),
            :switch => nil
          }]
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
        network_adapters [{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => nil,
            :vendor => 'Intel',
            :version => '80003ES2LAN',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'e1000e',
            :mounted => true,
            :device => 'eth0',
            :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-eth0.#{site_uid}.grid5000.fr"),
            :switch => 'gw'
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => nil,
            :vendor => 'Intel',
            :version => '80003ES2LAN',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'e1000e',
            :mounted => true,
            :device => 'eth1',
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :switch => 'gw',
            :switch_port => lookup('lille', "#{node_uid}", 'switch_port')
         },{
            :interface => 'Ethernet', 
            :rate => 1.G,
            :mac => nil,
            :vendor => nil,
            :version => nil,
            :enabled => true,
            :management => true,
            :mountable => false,
            :network_address => "#{node_uid}-ipmi.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-ipmi.#{site_uid}.grid5000.fr"),
            :switch => 'gw'
          },{
            :interface => 'Myrinet',
            :rate => 10.G,
            :mac => nil,
            :vendor => 'Myricom',
            :version => '10G-PCIE-8A-C',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'mx',
            :mounted => true,
            :device => 'myri0',
            :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-myri0.#{site_uid}.grid5000.fr"),
            :switch => nil
          }]
      end
    end
  end
  
end
