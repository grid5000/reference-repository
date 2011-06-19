site :bordeaux do |site_uid|

  cluster :bordereau do |cluster_uid|
    model "IBM System x3455"
    created_at Time.parse("2007-10-01 12:00 GMT").httpdate
    misc "IPMI 2.0, BIOS Version 1.32"
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
          :clock_speed => 2.6.G,
          :instruction_set => "x86-64",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => 64.KiB,
          :cache_l1d => 64.KiB,
          :cache_l2 => 1.MiB
        })
        main_memory({
          :ram_size => 4.GiB,
          :virtual_size => nil
        })
        operating_system({
	  :kadeploy_name => "debian-x64-5-prod",
          :kadeploy_version => "1",
          :name => "Debian Lenny",
          :release => nil,
          :version => nil
	})
        storage_devices [
          {:interface => 'SATA', :size => 80.GB, :driver => "sata_svw", :vendor => "Hitachi", :version => "HDS72168"}
          ]
        network_adapters [
          {:interface => 'Ethernet', :rate => 1.G,
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
	    :vendor => "Broadcom", :version => "BCM5704",
            :enabled => true, :mounted => true, :mountable => true, :driver => "tg3", :management => false, :device => "eth0",
	    :mac => get_macaddr("#{node_uid}.#{site_uid}.grid5000.fr","eth0")},
          {:interface => 'Ethernet', :rate => 1.G,
            :network_address => "#{node_uid}-eth1.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}-eth1.#{site_uid}.grid5000.fr"),
	    :vendor => "Broadcom", :version => "BCM5704",
            :enabled => true, :mounted => false, :mountable => true, :driver => "tg3", :management => false, :device => "eth1",
	    :mac => get_macaddr("#{node_uid}.#{site_uid}.grid5000.fr","eth1")}

          ]
      end
    end
  end # cluster bordereau

end
