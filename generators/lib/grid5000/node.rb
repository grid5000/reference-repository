module Grid5000
  class Node
    MiB = 1024**2
    
    attr_reader :properties, :cluster
    
    MAPPINGS = {
      "oar-2.4" => Proc.new{ |cluster, properties|
        # see https://www.grid5000.fr/mediawiki/index.php/OAR2_properties for list of properties
        h = {}
        main_network_adapter = properties["network_adapters"].find{|na|
          na['enabled'] && 
          na['mounted'] && 
          na['interface'] =~ /ethernet/i && 
          !na['management']
        }
        h['host']            = main_network_adapter['network_address']
        raise MissingProperty, "Node has no network_address" unless h['host']
        h['ip']              = main_network_adapter['ip']
        raise MissingProperty, "Node has no IP" unless h['ip']
        h['cluster']         = cluster.properties['uid']
        h['nodemodel']       = cluster.properties['model']
        h['switch']          = main_network_adapter['switch']
        h['besteffort']      = properties['supported_job_types']['besteffort'] ? "YES" : "NO"
        h['deploy']          = properties['supported_job_types']['deploy'] ? "YES" : "NO"
        h['ip_virtual']      = properties['supported_job_types']['virtual'] ? "YES" : "NO"
        h['virtual']         = properties['supported_job_types']['virtual']
        h['cpuarch']         = properties['architecture']['platform_type']
        h['cpucore']         = properties['architecture']['smt_size']/properties['architecture']['smp_size']
        h['cputype']         = [properties['processor']['model'], properties['processor']['version']].join(" ")
        h['cpufreq']         = properties['processor']['clock_speed']/1_000_000_000
        h['disktype']        = (properties['storage_devices'].first || {})['interface']
        h['ethnb']           = properties["network_adapters"].select{|na| na['interface'] =~ /ethernet/i}.length
        ib10g                = properties['network_adapters'].detect{|na| na['interface'] =~ /infiniband/i && na['rate'] == 10_000_000_000}
        h['ib10g']           = ib10g.nil? ? "NO" : "YES"
        h['ib10gmodel']      = ib10g.nil? ? "none" : ib10g['version']
        myri10g              = properties['network_adapters'].detect{|na| na['interface'] =~ /myri/i && na['rate'] == 10_000_000_000}
        h['myri10g']         = myri10g.nil? ? "NO" : "YES"
        h['myri10gmodel']    = myri10g.nil? ? "none" : myri10g['version']
        myri2g               = properties['network_adapters'].detect{|na| na['interface'] =~ /myri/i && na['rate'] == 2_000_000_000}
        h['myri2g']          = myri2g.nil? ? "NO" : "YES"
        h['myri2gmodel']     = myri2g.nil? ? "none" : myri2g['version']
        h['memcore']         = properties['main_memory']['ram_size']/properties['architecture']['smt_size']/MiB
        h['memcpu']          = properties['main_memory']['ram_size']/properties['architecture']['smp_size']/MiB
        h['memnode']         = properties['main_memory']['ram_size']/MiB
        properties["gpu"]  ||= {}
        h['gpu']             = (properties['gpu']['gpu'].is_a?(String) and properties['gpu']['gpu'].upcase == "SHARED") ? "SHARED" \
                                : properties['gpu']['gpu'] ? "YES" : "NO"
        h['gpu_count']       = properties['gpu']['gpu_count']
        h['gpu_model']       = properties['gpu']['gpu_model']
        properties["monitoring"] ||= {}
        h['wattmeter']       = (properties['monitoring']['wattmeter'].is_a?(String) and properties['monitoring']['wattmeter'].upcase == "SHARED") ? "SHARED" \
                                : properties['monitoring']['wattmeter'] ? "YES" : "NO"
        h['rconsole']        = properties['monitoring']['rconsole'] == false ? "NO" : "YES"
        h
      }
    }
    
    def initialize(cluster, properties)
      @cluster = cluster
      @properties = properties
    end
    
    def export(destination = "oar-2.4")
      if MAPPINGS.has_key?(destination)
        MAPPINGS[destination].call(cluster, properties)
      else
        raise ArgumentError, "Unsupported destination for export: #{destination.inspect}"
      end
    end
  end

end
