site :lyon do |site_uid|
  name "Lyon"
  location "Lyon, France"
  web
  description ""
  latitude 45.7667
  longitude 4.8333
  email_contact
  sys_admin_contact
  security_contact
  user_support_contact
  ( %w{sid-x64-base-1.0 sid-x64-base-1.1 sid-x64-nfs-1.0 sid-x64-nfs-1.1 sid-x64-big-1.1} + 
    %w{etch-x64-base-1.0 etch-x64-base-1.1 etch-x64-nfs-1.0 etch-x64-nfs-1.1 etch-x64-big-1.0 etch-x64-big-1.1 etch-x64-base-2.0 etch-x64-nfs-2.0 etch-x64-big-2.0} +
    %w{lenny-x64-base-0.9 lenny-x64-nfs-0.9 lenny-x64-big-0.9 lenny-x64-base-1.0 lenny-x64-nfs-1.0 lenny-x64-big-1.0 lenny-x64-base-2.0 lenny-x64-nfs-2.0 lenny-x64-big-2.0}  ).each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}
  
  cluster :capricorne do |cluster_uid|
    model "IBM eServer 325"
    created_at Time.parse("2004-12-01 12:00 GMT").httpdate
    misc "bios: 1.36 / bcm: 1.20.9 / bmc: 1.46"
    56.times do |i|
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
        network_adapters [{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => '',
            :enabled => true,
            :management => false,
            :mountable => false
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => '',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'tg3',
            :mounted => true,
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :device => 'eth1',
            :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"), 
            :switch => 'little-ego'
          },{       
            :interface => 'Myrinet',
            :rate => 2.G,
            :mac => '',
            :vendor => 'Myrinet',
            :version => "M3F-PCIXF-2",
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => '',
            :mounted => false,
            :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
            :device => 'myri0',
            :ip => dns_lookup("#{node_uid}-myri0.#{site_uid}.grid5000.fr")
          }]        
      end
    end    
  end # cluster capricorne
  
  cluster :sagittaire do |cluster_uid|
    model "Sun Fire V20z"
    created_at Time.parse("2006-07-01 12:00 GMT").httpdate
    79.times do |i|
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
          :version => "250",
          :clock_speed => 2.4.G,
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
          {:interface => 'SCSI', :size => 73.GB, :driver => "mptspi"}
          ]
        network_adapters [{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => '',
            :enabled => true,
            :management => false,
            :mountable => false,
            :driver => 'tg3', 
            :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-eth0.#{site_uid}.grid5000.fr")
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => '',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'tg3',
            :mounted => true,
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :device => 'eth1',
            :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"), 
            :switch => 'little-ego'
          }]        
      end
    end    
  end # cluster sagittaire
  
end
