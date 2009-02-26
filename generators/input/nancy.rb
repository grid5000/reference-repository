site :nancy do
  name "Nancy"
  location "Nancy, France"
  web
  description ""
  latitude
  longitude
  email_contact
  sys_admin_contact
  security_contact
  user_support_contact
  %w{sid-x64-base-1.0}.each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}
  
  cluster :grillon do
    model "HP ProLiant DL145G2"
    date_of_arrival Time.parse("2005-11-01 12:00 GMT").to_i
    47.times do |i|
      node "grillon-#{i+1}" do
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
          {:interface => 'SATA', :size => 80.GB(false), :driver => "sata_nv"}
          ]
        network_adapters [
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :driver => "tg3", :vendor => "Broadcom", :version => "BCM5721"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :driver => "tg3", :vendor => "Broadcom", :version => "BCM5721"}
          ]        
      end
    end
  end #cluster grillon
  
  cluster :grelon do
    model "HP ProLiant DL140G3"
    date_of_arrival Time.parse("2007-02-27 12:00 GMT").to_i
    120.times do |i|
      node "grelon-#{i+1}" do
        architecture({
          :smp_size => 2, 
          :smt_size => 4,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "Intel",
          :model => "Intel Xeon",
          :version => "5110",
          :clock_speed => 1.6.giga,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 4.MB
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
          {:interface => 'SATA', :size => 80.GB(false), :driver => "ata_piix"}
          ]
        network_adapters [
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :driver => "tg3", :vendor => "Broadcom", :version => "BCM5721"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :driver => "tg3", :vendor => "Broadcom", :version => "BCM5721"}
          ]
      end
    end
  end # cluster grelon
end