site :lyon do |site_uid|

  cluster :sagittaire do |cluster_uid|
    model "Sun Fire V20z"
    created_at Time.parse("2006-07-01 12:00 GMT").httpdate
    kavlan true
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
        if (i<69) then
          main_memory({
            :ram_size => 2.GiB, # bytes
            :virtual_size => nil
          })
        else
          main_memory({
            :ram_size => 16.GiB, # bytes
            :virtual_size => nil
          })
        end
        operating_system({
          :name => "Debian",
          :release => "6.0",
          :version => nil,
          :kernel => "2.6.32"
        })
        if (i<69) then
          storage_devices [
            {:interface => 'SCSI', :size => 73.GB, :driver => "mptspi"}
          ]
        else
          storage_devices [
            {:interface => 'SCSI', :size => 73.GB, :driver => "mptspi"},
            {:interface => 'SCSI', :size => 73.GB, :driver => "mptspi"}
          ]
        end
        network_adapters [{
          :interface => 'Ethernet',
          :rate => 1.G,
          :mac => lookup('sagittaire',"#{node_uid}",'network_interfaces','eth0','mac'),
          :vendor => 'Broadcom',
          :model => 'BCM5704',
          :enabled => true,
          :management => false,
          :mountable => true,
          :mounted => false,
          :driver => 'tg3',
          :ip => lookup('sagittaire',"#{node_uid}",'network_interfaces','eth0','ip'),
        },{
          :interface => 'Ethernet',
          :rate => 1.G,
          :mac => lookup('sagittaire',"#{node_uid}",'network_interfaces','eth1','mac'),
          :vendor => 'Broadcom',
          :model => 'BCM5704',
          :enabled => true,
          :management => false,
          :mountable => true,
          :bridged => true,
          :driver => 'tg3',
          :mounted => true,
          :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
          :device => 'eth1',
          :ip => lookup('sagittaire',"#{node_uid}",'network_interfaces','eth1','ip'),
          :switch => 'little-ego'
        }]
        gpu({
          :gpu  => false
           })

        monitoring({
          :wattmeter  => true
        })
      end
    end
  end # cluster sagittaire
end
