# coding: utf-8

require 'net/ssh'
require 'hashdiff'

# propriétés ignorées
IGNORED_PROPERTIES=%w{}

# Propriétés qui devraient être présentes
G5K_PROPERTIES=%w{api_timestamp available_upto besteffort chassis chunks cluster cluster_priority comment core core_count cpu cpuarch cpucore cpufreq cpuset cputype cpu_count deploy desktop_computing disk disk_reservation_count diskpath disktype drain eth_count eth_kavlan_count eth_rate exotic expiry_date finaud_decision gpu gpudevice gpu_model gpu_count grub host ib ib_count ib_rate id ip last_available_upto last_job_date links maintenance max_walltime memcore memcpu memnode mic myri myri_count myri_rate network_address next_finaud_decision next_state nodemodel production rconsole scheduler_priority slash_16 slash_17 slash_18 slash_19 slash_20 slash_21 slash_22 state state_num subnet_address subnet_prefix suspended_jobs switch thread_count type virtual vlan wattmeter opa_count opa_rate gpu_mem gpu_compute_capability gpu_compute_capability_major}.sort - IGNORED_PROPERTIES

# abacus15 a été retired avant qu'on puisse corriger le cpu_affinity des GPUs,
# par conséquent on ne peut plus regénérer ses propriétés OAR il faut l'ignorer
# lors de la validation.
WRONG_GPU_EXCEPTIONS=%w{abacus15-1.rennes.grid5000.fr abacus15-2.rennes.grid5000.fr}.freeze


module RefRepo::Valid::OarProperties
  def self.check(options)
    ret = true
    options[:sites].each do |site|
      puts "Checking site #{site}..."
      resources = RefRepo::Utils::get_api("sites/#{site}/internal/oarapi/resources/details.json?limit=1000000")['items']

      default_resources = resources.select { |e| e['type'] == 'default' }.sort_by { |e| e['id'] }
      disk_resources = resources.select { |e| e['type'] == 'disk' }.sort_by { |e| e['id'] }
      if not options[:clusters].empty?
        puts "Restricting to resources of clusters #{options[:clusters].join(',')}"
        default_resources.select! { |e| options[:clusters].include?(e['cluster']) }
      end

      # Checking scheduler_priority
      default_resources.each do |r|
        if r['scheduler_priority'] < 0
          puts "Invalid scheduler_priority value on #{r['id']}/#{r['network_address']}: #{r['scheduler_priority']}"
          ret = false
        end
      end

      # Non-default resources must have available_upto = 0 (see bug 8062)
      resources.select { |e| e['type'] != 'default' }.sort_by { |e| e['id'] }.each do |r|
        if r['available_upto'] != 0
          puts "Invalid available_upto value on #{r['id']} (type=#{r['type']}, state=#{r['state']}): #{r['available_upto']} (should be 0)"
          ret = false
        end
      end

      # Checking list of properties
      names = default_resources.map { |e| e.keys.sort }.uniq.first - IGNORED_PROPERTIES
      if names != G5K_PROPERTIES
        puts "ERROR: wrong list of properties:"
        ret = false
        puts "- " + (G5K_PROPERTIES - names).join(' ')
        puts "+ " + (names - G5K_PROPERTIES).join(' ')
      end

      # 'core' must be globally unique
      dupe_cores = default_resources.map { |e| e.slice('id', 'core', 'host', 'cpu', 'cpuset') }.group_by { |e| e['core'] }.to_a.select { |e| e[1].length > 1 }
      unless dupe_cores.empty?
        puts "ERROR: some resources have the same 'core' value. it should be globally unique over the site."
        ret = false
        pp dupe_cores if options[:verbose]
      end

      # 'cpu' must be unique to a 'host'
      dupe_cpus = default_resources.map { |e| [e['cpu'], e['host'] ]}.uniq.group_by { |e| e[0] }.to_a.select { |e| e[1].length > 1 }
      unless dupe_cpus.empty?
        puts "ERROR: some hosts have the same 'cpu' value. it should be globally unique over the site."
        ret = false
        pp dupe_cores if options[:verbose]
      end

      # for each host ...
      default_resources.map { |e| e['host'] }.uniq.each do |host|
        host_resources = default_resources.select { |e| e['host'] == host }
        host_disks = disk_resources.select { |e| e['host'] == host }
        cluster = host_resources.first['cluster']
        next if not options[:clusters].empty? and not options[:clusters].include?(cluster)

        # check number of reservable disks against disk_reservation_count
        disk_reservation_count = host_resources.map{ |e| e['disk_reservation_count'] }.uniq
        if disk_reservation_count.length > 1
          raise "Invalid: varying disk_reservation_count inside cluster!"
        end
        disk_reservation_count = disk_reservation_count.first || 0
        if disk_reservation_count != host_disks.count
          puts "ERROR: Discrepancy found between the number of disks (#{host_disks.count}) and \"disk_reservation_count\" (#{disk_reservation_count}) for #{host}"
          ret = false
        end

        # compute nbcores.
        # cpucore is cores per cpu. to know the number of cpus, we devide memnode per memcpu.
        nbcores = host_resources.map { |e| e['cpucore'] * (e['memnode'] / e['memcpu']) }.uniq
        if nbcores.length > 1
          raise "Invalid: varying nbcores inside cluster!"
        end
        nbcores = nbcores.first

        if host_resources.length != nbcores
          puts "ERROR: invalid number of resources for #{host}. should be nbcores. (host_resources.length=#{host_resources.length} ; nbcores=#{nbcores})"
          ret = false
        end

        # ids and cores should be in the same order
        host_cores = host_resources.map { |e| e['core'] }
        host_cores_min = host_cores.first
        host_cores_max = host_cores.last
        if host_cores_max - host_cores_min + 1 != nbcores
          puts "ERROR: core values for #{host} are not sequential"
          ret = false
        end
        # the first cpuset should be 0
        host_cpusets = host_resources.map { |e| e['cpuset'] }.sort
        host_cpusets_min = host_cpusets.first
        host_cpusets_max = host_cpusets.last
        if host_cpusets_min != 0
          puts "ERROR: first cpuset value for #{host} should be 0"
          ret = false
        end
        # the last cpuset should be nbcores-1, on aarch64 cpuset are not sequential
        if host_cpusets_max - host_cpusets_min + 1 != nbcores and host_resources.map { |e| e['cpuarch']} == 'x86_64'
          puts "ERROR: cpuset values for #{host} are not sequential"
          ret = false
        end
        if options[:verbose] and (host_cpusets_max - host_cpusets_min + 1 != nbcores or host_cores_max - host_cores_min + 1 != nbcores)
          puts "id   cpu   core   cpuset"
          pp(host_resources.map { |e| [e['id'], e['cpu'], e['core'], e['cpuset'] ] })
        end

        # if a node has GPUs, then all resources must be affected to a GPU
        host_resources = default_resources.select { |e| e['host'] == host && !WRONG_GPU_EXCEPTIONS.include?(e['host']) }
        if host_resources.find { |r| r['gpu'] }
          if host_resources.find { |r| r['gpu'].nil? }
            puts "ERROR: #{host} has GPU(s), but some resources have no GPUs affected. Reserving all GPUs should reserve the whole node, and reserving 1/N GPUs should reserve 1/N of the node."
            host_resources.group_by { |r| r['gpu'] }.each_pair do |gpu, prop|
              cpus = prop.map { |e| e['cpu'] }.uniq.sort.join(',')
              cores = prop.map { |e| e['core'] }.uniq.sort.join(',')
              rids = prop.map { |e| e['resource_id'] }.uniq.sort.join(',')
              puts "gpu=#{gpu ? gpu : 'NULL'} for resources with: cpu=#{cpus} core=#{cores} resource_id=#{rids}"
            end
            ret = false
          end
        end
      end
    end
    return ret
  end
end
