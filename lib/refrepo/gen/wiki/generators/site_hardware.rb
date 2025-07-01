# coding: utf-8

require 'refrepo/gpu_ref'

class SiteHardwareGenerator < WikiGenerator

  def initialize(page_name, site)
    super(page_name)
    @site = site
  end

  def generate_content(_options)
    has_reservable_disks = false
    has_unsupported_gpu = false
    has_omni_path = false
    G5K::get_global_hash['sites'][@site]['clusters'].each do |_,c|
      c['nodes'].each do |_,n|
        n['storage_devices'].each do |d|
          has_reservable_disks ||= d['reservation']
        end

        if ! n['gpu_devices'].nil?
          has_unsupported_gpu ||= n['gpu_devices'].map { |_, g| g['model'] }.uniq
            .map{|gpu_model| GPURef.is_gpu_supported?(gpu_model)}.reduce(:&)
        end

        n['network_adapters'].each do |net|
          has_omni_path ||= true if net['interface'] == "Omni-Path"
        end
      end
    end

    asterisks = []
    asterisks << "''*: disk is [[Disk_reservation|reservable]]''" if has_reservable_disks
    asterisks << "''**: crossed GPUs are not supported by Grid'5000 default environments''" if has_unsupported_gpu
    asterisks << "''***: OPA (Omni-Path Architecture) is currently not supported on Debian 12 environment''" if has_omni_path

    @generated_content = "__NOEDITSECTION__\n" +
      "{{Portal|User}}\n" +
      "<div class=\"sitelink\">Hardware: [[Hardware|Global]] | " + G5K::SITES.map { |e| "[[#{e.capitalize}:Hardware|#{e.capitalize}]]" }.join(" | ") + "</div>\n" +
      "'''See also:''' [[#{@site.capitalize}:Network|Network topology for #{@site.capitalize}]]\n" +
      "#{SiteHardwareGenerator.generate_header_summary({@site => G5K::get_global_hash['sites'][@site]})}\n" +
      "= Clusters summary =\n" +
      self.class.generate_summary(@site, false, asterisks) +
      self.class.generate_description(@site) +
      MW.italic(MW.small(generated_date_string)) +
      MW::LINE_FEED
  end

  def self.generate_all_clusters
    table_columns = []
    table_data = []
    G5K::SITES.each{ |site|
      table_columns = self.generate_summary_data(site, true)[0]
      table_data += self.generate_summary_data(site, true)[1]
    }
    generate_split_tables(table_columns, table_data, true, [])
  end

  def self.generate_split_tables(table_columns, table_data, with_site, asterisks)
    column = with_site ? 2 : 1
    output = ''
    [
      [ '== Default queue resources ==', /(^$|exotic)/ ],
      [ '== Abaca queue resources ==', /production/],
      [ '== Testing queue resources ==', /testing/]
    ].each do |title,regexp|
      if table_data.select{ |row| row[column] =~ regexp}.length > 0
        output += "#{title}\n"
        output += MW.generate_table('class="wikitable sortable"', table_columns, table_data.select{ |row| row[column] =~ regexp }) + "\n"
        if asterisks.length >0
          output += asterisks.join("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;") + "\n"
        end
      end
    end
    output
  end

  def self.generate_header_summary(sites_hash)
    store = Hash.new { |h,k| h[k] = Hash.new(0) }
    store[''][:sites] = Set.new()

    sites_hash.sort.to_h.each do |_site_uid, site_hash|
      store[''][:sites].add(site_hash['uid'])
      clusters_hash = site_hash.fetch('clusters', {})
      store[''][:clusters] += clusters_hash.length
      clusters_hash.sort.to_h.each do |_cluster_uid, cluster_hash|
        cluster_hash['queues'].each do |queue|
          store[queue][:sites] = Set.new() unless store[queue][:sites].is_a?(Set)
          store[queue][:sites].add(site_hash['uid'])
          store[queue][:clusters] += 1
        end
        cluster_hash['nodes'].sort.to_h.each do |_node_uid, node_hash|
          store_fill(cluster_hash['queues'], node_hash, store)
        end
      end
    end

    summary = print_header_summary('= Summary =', '', store)

    if store.key?('default') && store.key?('production')
      # Split column setup
      ## Full width outer-table
      summary += MW::TABLE_START + 'width="100%" border="0"'+ MW::LINE_FEED
      summary += MW::TABLE_ROW + MW::LINE_FEED

      ## Half-width first cell
      summary += MW::TABLE_CELL + ' width="50%" valign="top" ' + MW::TABLE_CELL + MW::LINE_FEED
      ## 1st inner table
      summary += MW::TABLE_START + ' width="100%"' + MW::LINE_FEED
      summary += print_header_summary('=== Default queue resources ===', 'default', store)
      summary += MW::TABLE_END + MW::LINE_FEED

      ## Half-width second cell
      summary += MW::TABLE_CELL + ' width="50%" valign="top" ' + MW::TABLE_CELL + MW::LINE_FEED
      ## 2st inner table
      summary += MW::TABLE_START + ' width="100%"' + MW::LINE_FEED
      summary += print_header_summary('=== Abaca queue resources ===', 'production', store)
      summary += MW::TABLE_END + MW::LINE_FEED

      ## End outer-tablie
      summary += MW::TABLE_END + MW::LINE_FEED
    end
    summary
  end

  def self.store_fill(queues, node_hash, store)
    ([''] + queues).each do |queue|
      store[queue][:nodes] += 1
      store[queue][:cores] += node_hash['architecture']['nb_cores']
      store[queue][:ram] += node_hash['main_memory']['ram_size']
      store[queue][:pmem] += node_hash['main_memory']['pmem_size'] if node_hash['main_memory']['pmem_size']
      if node_hash['gpu_devices']
       store[queue][:gpus] += node_hash['gpu_devices'].length
       store[queue][:gpus_cores] += node_hash['gpu_devices'].map { |_k, g| g['cores']}.sum
      end
      store[queue][:ssds] += node_hash['storage_devices'].select { |d| d['storage'] == 'SSD' }.length
      store[queue][:hdds] += node_hash['storage_devices'].select { |d| d['storage'] == 'HDD' }.length
      node_hash['storage_devices'].each do |i|
        store[queue][:storage_space] += i['size']
      end
      store[queue][:flops] += node_hash['performance']['node_flops']
    end
  end

  def self.print_header_summary(title, queue, store)
    output = "#{title}\n"
    output += "* #{store[queue][:sites].size} sites\n" if store[queue][:sites].size > 1
    output += "* #{store[queue][:clusters]} cluster" + (store[queue][:clusters] > 1 ? "s":'') + "\n"
    output += "* #{store[queue][:nodes]} nodes\n"
    output += "* #{store[queue][:cores]} CPU cores\n"
    # GPU?
    if store[queue][:gpus] > 0
      output += "* #{store[queue][:gpus]} GPUs\n"
      output += "* #{store[queue][:gpus_cores]} GPUs cores\n"
    end
    # RAM and PMEM?
    output += "* #{G5K.get_size(store[queue][:ram])} RAM"
    output += " + #{G5K.get_size(store[queue][:pmem])} PMEM" if store[queue][:pmem] > 0
    output += "\n"
    # SDD? and HDD
    output += "* "
    output += "#{store[queue][:ssds]} SSDs and " if store[queue][:ssds] > 0
    output += "#{store[queue][:hdds]} HDDs on nodes (total: #{G5K.get_size(store[queue][:storage_space], 'metric')})\n"
    #tflops
    tflops = sprintf("%.1f", store[queue][:flops].to_f / (10**12))
    output += "* #{tflops} TFLOPS (excluding GPUs)\n"
    output
  end


  def self.generate_summary(site, with_sites, asterisks)
    table_columns, table_data = self.generate_summary_data(site, with_sites)
    if table_data.flatten.any?(/(production|testing)/)
      generate_split_tables(table_columns, table_data, with_sites, asterisks)
    else
      MW.generate_table('class="wikitable sortable"', table_columns, table_data) + "\n" + asterisks.join("\n\n")
    end
  end

  def self.generate_summary_data(site, with_sites)
    table_columns = []
    table_data = []

    hardware = get_hardware([site])

    site_accelerators = 0
    hardware[site].sort.to_h.each { |_cluster_uid, cluster_hash|
      site_accelerators += cluster_hash.select { |_k, v| v['accelerators'] != '' }.count
    }

    hardware[site].sort_by{|cluster_uid, _cluster_hash| split_cluster_node(cluster_uid) }.to_h.each { |cluster_uid, cluster_hash|
      cluster_nodes = cluster_hash.keys.flatten.count
      queue = cluster_hash.map { |_k, v| v['queue']}.first
      access_conditions = []
      if queue == 'production' || queue == 'abaca'
        access_conditions << "<b>[[Grid5000:UsagePolicy#Rules_for_the_production_queue|abaca]]</b>&nbsp;queue"
      elsif queue != ''
        access_conditions << "<b>#{queue}</b>&nbsp;queue"
      end
      access_conditions << "<b>[[Exotic##{site.capitalize}:_#{cluster_uid}|exotic]]</b>&nbsp;job&nbsp;type" if cluster_hash.map { |_k, v| v['exotic']}.first
      table_columns = []
      table_columns << (with_sites == true ? [{attributes: 'rowspan=2', text: 'Site'}] : []) + [{attributes: 'rowspan=2', text: 'Cluster'},  {attributes: 'rowspan=2', text: 'Access Condition'}, {attributes: 'rowspan=2', text: 'Date of arrival'}, {attributes: 'rowspan=2', text: 'Manufacturing date'},{ attributes: 'data-sort-type="number" rowspan=2', text: 'Nodes' }, {attributes: 'colspan=4', text:  'CPU'}, { attributes: 'data-sort-type="number" rowspan=2', text: 'Memory' }, { attributes: 'data-sort-type="number" rowspan=2', text: 'Storage' }, { attributes: 'data-sort-type="number" rowspan=2', text: 'Network' }] + ((site_accelerators.zero? && with_sites == false) ? [] : [{attributes: 'rowspan=2', text: 'Accelerators'}])
      table_columns << [{ attributes: 'data-sort-type="number"', text: '#' }, 'Name', { attributes: 'data-sort-type="number"', text: 'Cores' }, 'Architecture' ]
      data = partition(cluster_hash)
      table_data <<  (with_sites == true ? ["[[#{site.capitalize}:Hardware|#{site.capitalize}]]"] : []) + [
        (with_sites == true ? "[[#{site.capitalize}:Hardware##{cluster_uid}" + "|#{cluster_uid}]]" : "[[##{cluster_uid}" + "|#{cluster_uid}]]"),
        access_conditions.join(",<br/>"),
        cell_data(data, 'date'),
        cell_data(data, 'manufacturing_date'),
        cluster_nodes,
        cell_data(data, 'cpus_per_node'),
        cell_data(data, 'processor_model'),
        cell_data(data, 'cores_per_cpu_str'),
        cell_data(data, 'architecture'),
        'data-sort-value="' + sort_data(data, 'memory_size') + '"|' + sort_data(data, 'ram_size') + (!data['pmem_size'].nil? ? " + #{cell_data(data, 'pmem_size')} [[PMEM]]" : ''),
        'data-sort-value="' + sort_data(data, 'storage_size') + '"|' + cell_data(data, 'storage'),
        'data-sort-value="' + sort_data(data, 'network_throughput') + '"|' + cell_data(data, 'used_networks')
      ] + ((site_accelerators.zero? && with_sites == false) ? [] : [cell_data(data, 'accelerators')])
    }
    [table_columns, table_data]
  end

  def self.get_queue_drawgantt_url(site, queue)
    url = "https://intranet.grid5000.fr/oar/#{site.capitalize}/"
    if (queue == 'production' || queue == 'abaca')
      url += "drawgantt-svg-prod/"
    #elsif (queue == 'testing')
    #  url += "drawgantt-svg/?filter=with%20testing" # Here we miss a filter "only testing"
    else
      url += "drawgantt-svg/"
    end
    url
  end

  def self.generate_description(site)
    text_data = []

    hardware = get_hardware([site])

    site_accelerators = 0
    hardware[site].sort.to_h.each { |_cluster_uid, cluster_hash|
      site_accelerators += cluster_hash.select { |_k, v| v['accelerators'] != '' }.count
    }

    # Group by queue
    # Alphabetic ordering of queue names matches what we want: "default" < "production" < "testing"
    hardware[site].group_by { |_cluster_uid, cluster_hash| cluster_hash.map { |_k, v| v['queue']}.first }.sort.each { |queue, clusters|
      queue = (queue.nil? || queue.empty?) ? 'default' : queue
      queue_drawgantt_url = get_queue_drawgantt_url(site, queue)
      if (queue != 'testing')
        text_data << "\n= Clusters in the [#{queue_drawgantt_url} #{queue == 'production' ? 'abaca' : queue} queue] ="
      else
        text_data << "\n= Clusters in the #{queue == 'production' ? 'abaca' : queue} queue ="
      end
      clusters.sort_by{|cluster_uid, _cluster_hash| split_cluster_node(cluster_uid) }.to_h.each { |cluster_uid, cluster_hash|
        subclusters = cluster_hash.keys.count != 1
        cluster_nodes = cluster_hash.keys.flatten.count
        cluster_cpus = cluster_hash.map { |k, v| k.count * v['cpus_per_node'] }.reduce(:+)
        cluster_cores = cluster_hash.map { |k, v| k.count * v['cpus_per_node'] * v['cores_per_cpu'] }.reduce(:+)
        queue_str = cluster_hash.map { |_k, v| v['queue_str']}.first
        access_conditions = []
        access_conditions << queue_str if queue_str != ''
        access_conditions << "[[Exotic##{site.capitalize}:_#{cluster_uid}|exotic]] job type" if cluster_hash.map { |_k, v| v['exotic']}.first

        cluster_drawgantt_url = get_queue_drawgantt_url(site, queue)+"?filter=#{cluster_uid}%20only"
        text_data <<  ["\n== [#{cluster_drawgantt_url} #{cluster_uid}] ==\n"]
        text_data << ["'''#{cluster_nodes} #{G5K.pluralize(cluster_nodes, 'node')}, #{cluster_cpus} #{G5K.pluralize(cluster_cpus, 'cpu')}, #{cluster_cores} #{G5K.pluralize(cluster_cores, 'core')}" + (subclusters == true ? ",''' split as follows due to differences between nodes " : "''' ") + "([https://public-api.grid5000.fr/stable/sites/#{site}/clusters/#{cluster_uid}/nodes.json?pretty=1 json])"]

        reservation_cmd = "\n{{Term|location=f#{site}|cmd="
        reservation_cmd += "<code class=\"command\">oarsub</code> "
        reservation_cmd += "<code class=\"replace\">-q #{queue == 'production' ? 'abaca' : queue}</code> "
        reservation_cmd += "<code class=\"replace\">-t exotic</code> " if cluster_hash.map { |_k, v| v['exotic']}.first
        reservation_cmd += "<code class=\"env\">-p #{cluster_uid}</code> "
        reservation_cmd += "<code>-I</code>"
        reservation_cmd += "}}\n"
        text_data << "\n'''Reservation example:'''"
        text_data << reservation_cmd

        if queue == 'production' || queue == 'abaca'
          walltime_breakout_text = "'''Max walltime per nodes:'''\n"
          nodes = G5K::get_global_hash['sites'][site]['clusters'][cluster_uid]['nodes']
          max_walltime_per_node = nodes.map { |node_name,node|
            [node['supported_job_types']['max_walltime']/3600,node_name.sub("#{cluster_uid}-",'').to_i]
          }
          walltime_breakout = {}
          max_walltime_per_node.each { |e|
            if walltime_breakout[e[0]]
              walltime_breakout[e[0]] << e[1]
            else
              walltime_breakout[e[0]] = [e[1]]
            end
          }
          # https://stackoverflow.com/questions/20847212/how-to-convert-an-array-of-number-into-ranges
          walltime_breakout.sort.each { |hours, allnodes|
            prev = allnodes[0]
            range = allnodes.sort.slice_before { |node|
              prev, prev2 = node, prev
              prev2 + 1 != node}.map{|b,*,c| c ? "#{b}-#{c}" : b.to_s }
              range_text = (range.length>1 or range[0].include? '-' ) ? "[#{range.join(',')}]" : range[0]
              walltime_breakout_text << "* #{cluster_uid}-#{range_text}: #{hours}h\n"
          }
          text_data << walltime_breakout_text
        end

        cluster_hash.sort.to_h.each_with_index { |(num, h), i|
          if subclusters
            subcluster_nodes = num.count
            subcluster_cpus = subcluster_nodes * h['cpus_per_node']
            subcluster_cores = subcluster_nodes * h['cpus_per_node'] * h['cores_per_cpu']
            text_data << "<hr style=\"height:10pt; visibility:hidden;\" />\n" if i != 0 # smaller vertical <br />
            text_data << ["; #{cluster_uid}-#{G5K.nodeset(num)} (#{subcluster_nodes} #{G5K.pluralize(subcluster_nodes, 'node')}, #{subcluster_cpus} #{G5K.pluralize(subcluster_cpus, 'cpu')}, #{subcluster_cores} #{G5K.pluralize(subcluster_cores, 'core')})"]
          end

          accelerators = nil
          if h['gpu_str'] != '' && h['mic_str'] != '' && h['fpga_str'] != ''
            accelerators = 'GPU/Xeon Phi/FPGA'
          elsif h['gpu_str'] != ''
            accelerators = 'GPU'
          elsif h['mic_str'] != ''
            accelerators = 'Xeon Phi'
          elsif h['fpga_str'] != ''
            accelerators = 'FPGA'
          end
          hash = {}
          hash['Access condition'] = access_conditions.join(", ") if not access_conditions.empty?
          hash.merge!({
            'Model' => h['model'],
            'Manufacturing date' => h['manufacturing_date'],
            'Date of arrival' => h['date'],
            'CPU' => h['processor_description'],
            'Memory' => h['ram_size'] + (!h['pmem_size'].nil? ? " + #{h['pmem_size']} [[PMEM]]" : ''),
            'Storage' => h['storage_description'],
            'Network' => h['network_description'],
          })
          hash[accelerators] = h['accelerators_long'] if accelerators
          text_data << MW::generate_hash_table(hash)
        }
        text_data << "\n'''Note:''' This cluster is defined as exotic. Please read the '''[[Exotic##{site.capitalize}:_#{cluster_uid}|exotic]]''' page for more information.<br/>" if cluster_hash.map { |_k, v| v['exotic']}.first
      }
    }

    return text_data.join("\n")
  end
end

# Partitioning the hash values
def partition(cluster_hash)
  data = {}
  h1 = {}
  cluster_hash.sort.to_h.each { |_num2, h2|
    h2.each_key{ |k|
      h1[k] = []
      cluster_hash.sort.to_h.each { |num3, h3|
        if h1[k].map {|e| e['value']}.include?(h3[k])
          num = (h1[k].select { |e| e['value'] == h3[k] }).first['num']
          h1[k].delete_if { |e| e['value'] == h3[k] }
          h1[k] += [{ 'num' => num + num3, 'value' => h3[k], 'cell' => "#{G5K.nodeset(num + num3)}: #{h3[k]}", 'sort' => "#{h3[k]}"}]
        else
          h1[k] += [{ 'num' => num3, 'value' => h3[k], 'cell' => "#{G5K.nodeset(num3)}: #{h3[k]}", 'sort' => "#{h3[k]}"}]
        end
      }
      h1[k].first['cell'] = h1[k].first['cell'].split(': ')[1] if h1[k].count == 1
      data[k] = h1[k].sort_by{ |e| e['num'].sort[0] }
    }
  }
  data
end

def cell_data(data, key)
  data[key].map{ |e| e['cell'] }.join('<br />')
end

def sort_data(data, key)
  data[key].map{ |e| e['sort'] }[0]
end

def gpu_description(node_hash, long_names)
  lgpu = node_hash['gpu_devices']
  res = []
  if lgpu
    gpu_types = lgpu.values.group_by{|device_hash| device_hash['model']}.map do |model_name, device_hashes|
      description = gpu_model_description(device_hashes.first, long_names)
      [model_name, {number: device_hashes.length, description: description}]
    end.to_h

    gpu_types.each{|_model, hash|
      res << (hash[:number] == 1 ? '' : hash[:number].to_s + '&nbsp;x&nbsp;') + hash[:description]
    }

  end
  return res.join(", ")
end

def gpu_model_description(device_hash, long_name)
  model = long_name ? device_hash['model'] : GPURef.model2shortname(device_hash['model'])
  memgib = (device_hash['memory'].to_f/2**30).round(0)
  vendor = device_hash['vendor']
  description = vendor.to_s + ' ' + model.to_s.gsub(' ', '&nbsp;') + "&nbsp;(#{memgib}&nbsp;GiB)"
  if long_name
    cc = device_hash['compute_capability']
    description += "<br>Compute&nbsp;capability:&nbsp;#{cc}" if cc
    description = "<s>" + description + "</s><br>''not supported by Grid'5000 default environments''" if !GPURef.is_gpu_supported?(device_hash)
  else
    description = "<s>" + description + "</s>**" if !GPURef.is_gpu_supported?(device_hash)
  end
  return description
end

def get_hardware(sites)
  global_hash = G5K::get_global_hash

  # Loop over each cluster of the site
  hardware = {}
  global_hash['sites'].sort.to_h.select{ |site_uid, _site_hash| sites.include?(site_uid) }.each { |site_uid, site_hash|
    hardware[site_uid] = {}
    site_hash.fetch('clusters', {}).sort.to_h.each { |cluster_uid, cluster_hash|
      hardware[site_uid][cluster_uid] = {}
      cluster_hash.fetch('nodes').sort.each { |node_uid, node_hash|
        next if node_hash['status'] == 'retired'
        # map model to vendor (eg: {'SAS5484654' => 'Seagate', 'PX458' => 'Toshiba' ...}
        hard = {}
        queue = cluster_hash['queues'] - ['admin', 'default']
        hard['queue'] = (queue.nil? || queue.empty?) ? '' : queue[0]
        hard['queue_str'] = (queue.nil? || queue.empty?) ? '' : queue[0] + G5K.pluralize(queue.count, ' queue')
        hard['exotic'] = cluster_hash['exotic']
        hard['date'] = Date.parse(cluster_hash['created_at'].to_s).strftime('%Y-%m-%d')
        hard['manufacturing_date'] = cluster_hash['manufactured_at']
        hard['model'] = cluster_hash['model']
        hard['processor_model'] = "#{node_hash['processor']['vendor']} "
        hard['processor_model'] += node_hash['processor']['model'].gsub(/^#{node_hash['processor']['vendor']} /,'')
        if node_hash['processor']['version'] != 'Unknown'
          hard['processor_model'] += " #{node_hash['processor']['version']}"
        end
        if node_hash['processor']['other_description'] =~ /@/
          hard['processor_freq'] = node_hash['processor']['other_description'].split('@')[1].strip
        end
        hard['microarchitecture'] = node_hash['processor']['microarchitecture']
        hard['cpus_per_node'] = node_hash['architecture']['nb_procs']
        hard['cpus_per_node_str'] = hard['cpus_per_node'].to_s + '&nbsp;' + G5K.pluralize(hard['cpus_per_node'], 'CPU') + '/node'
        hard['cores_per_cpu'] = node_hash['architecture']['nb_cores'] / hard['cpus_per_node']
        hard['cores_per_cpu_str'] = hard['cores_per_cpu'].to_s + '&nbsp;' + G5K.pluralize(hard['cores_per_cpu'], 'core') + '/CPU'
        hard['architecture'] = node_hash['architecture']['platform_type']
        exotic_archname = get_exotic_archname(node_hash['architecture']['platform_type'])
        hard['num_processor_model'] = (hard['cpus_per_node'] == 1 ? '' : "#{hard['cpus_per_node']}&nbsp;x&nbsp;") + (exotic_archname ? "#{exotic_archname}&nbsp;" : '') + hard['processor_model'].gsub(' ', '&nbsp;')
        hard['processor_description'] = "#{hard['processor_model']} (#{hard['microarchitecture']}), #{hard['architecture']}#{hard['processor_freq'] ?  ', ' + hard['processor_freq'] : ''}, #{hard['cpus_per_node_str']}, #{hard['cores_per_cpu_str']}"
        hard['ram_size'] = G5K.get_size(node_hash['main_memory']['ram_size'])
        hard['memory_size'] = node_hash['main_memory']['ram_size']
        hard['pmem_size'] = G5K.get_size(node_hash['main_memory']['pmem_size']) unless node_hash['main_memory']['pmem_size'].nil?
        #hard['memory_size'] += node_hash['main_memory']['pmem_size'] unless node_hash['main_memory']['pmem_size'].nil?
        storage = node_hash['storage_devices'].sort_by!{ |d| d['id']}.map { |i| { 'size' => i['size'], 'tech' => i['storage'], 'reservation' => i['reservation'].nil? ? false : i['reservation'] } }
        hard['storage'] = storage.each_with_object(Hash.new(0)) { |data, counts|
          counts[data] += 1
        }.to_a
          .map.with_index { |e, i|
          size = G5K.get_size(e[0]['size'], 'metric')
          if i.zero?
            if e[1] == 1
              "<b>#{size}&nbsp;#{e[0]['tech']}</b>"
            else
              "<b>#{size}&nbsp;#{e[0]['tech']}</b>" + ' +&nbsp;' + ((remainder = e[1] - 1) == 1 ? '' : "#{remainder}&nbsp;x&nbsp;") + "#{size}&nbsp;#{e[0]['tech']}" + (e[0]['reservation'] ? '[[Disk_reservation|*]]' : '')
            end
          else
            if e[1] == 1
              "#{size}&nbsp;#{e[0]['tech']}" + (e[0]['reservation'] ? '[[Disk_reservation|*]]' : '')
            else
              e[1].to_s + "&nbsp;x&nbsp;#{size}&nbsp;#{e[0]['tech']}" + (e[0]['reservation'] ? '[[Disk_reservation|*]]' : '')
            end
          end
        }.join(' +&nbsp;')

        hard['storage_size'] = storage.inject(0){|sum, v| sum + (v['size'].to_f / 2**30).floor }.to_s # round to GB to avoid small differences within a cluster
        storage_description = node_hash['storage_devices'].sort { |a,b|
          a['device'] <=> b['device']
        }.map do |v|
          {
            'device' => v['device'],
            'size' => v['size'],
            'tech' => v['storage'],
            'id' => v['id'],
            'interface' => v['interface'],
            'vendor' => v['vendor'],
            'model' => v['alt_model_name'] || v['model'],
            'path' => v['by_path'] || v['by_id'],
            'count' => node_hash['storage_devices'].count,
            'reservation' => v['reservation'].nil? ? false : v['reservation']
          }
        end

        has_reservable_disks = false
        hard['storage_description'] = storage_description.sort_by!{ |d| d['id']}.map { |e|
          has_reservable_disks ||= e['reservation']
          [
            e['count'] > 1 ? "\n*" : '',
            e['id'] + ',',
            G5K.get_size(e['size'],'metric'),
            e['tech'],
            e['interface'],
            e['vendor'],
            e['model'],
            '(dev: <code class="file">/dev/' + e['id'] + '</code>' + (e['reservation'] ? '[[Disk_reservation|*]]' : '') + ')',
            e['reservation'] ? '[[Disk_reservation|(reservable)]]' : '',
            e['id'] == 'disk0' ? '(primary disk)' : ''
          ].join(' ')
        }.join('<br />')

        network = node_hash['network_adapters'].select { |v|
          v['management'] == false &&
          (v['device'] =~ /\./).nil? # exclude PKEY / VLAN interfaces see #9417
        }.map{|v| {
            'rate' => v['rate'],
            'interface' => v['interface'],
            'sriov' => v['sriov'],
            'used' => (v['enabled'] and (v['mounted'] or v['mountable']))
          }
        }
        hard['used_networks'] = network.select { |e|
          e['used'] == true
        }.each_with_object(Hash.new(0)) { |data, counts|
          counts[data] += 1
        }.to_a.sort_by { |e|
          e[0]['rate'].to_f
        }.map{ |e|
          get_network_info(e, false)
        }.join('+&nbsp;')

        hard['network_throughput'] = network.select { |e|
          e['used'] == true
        }.inject(0){ |sum, v|
          sum + (v['rate'].to_f / 10**6).floor
        }.to_s # round to Mbps

        network_description = node_hash['network_adapters'].select { |v|
          v['management'] == false &&
          (v['device'] =~ /\./).nil? # exclude PKEY / VLAN interface see #9417
        }.map{ |v|
          {
            'device' => v['device'],
            'name' => v['name'],
            'rate' => v['rate'],
            'interface' => v['interface'],
            'driver' => v['driver'],
            'sriov' => v['sriov'],
            'unwired' => v['enabled'] == false,
            'unavailable_for_experiment' => v['mountable'] == false,
            'no_kavlan' => (v['interface'] == 'Ethernet' &&
              v['mountable'] == true &&
              v['kavlan'] == false),
            'model' => (v['vendor'] || 'N/A') + ' ' + (v['model'] || 'N/A'),
            'count' => node_hash['network_adapters'].count
          }
        }.sort_by{ |e|
          e['device']
        }
        nic_c = 0
        hard['network_description'] = network_description.map do |e|
          desc = []
          if e['name'].nil? or e['name'] == e['device']
            desc << e['device']
          else
            desc << e['device'] + "/" + e['name']
          end
          desc << e['interface']

          if !(e['unwired'] and e['unavailable_for_experiment'])
            desc << 'configured rate: ' + (e['unwired'] ? 'n/c' : G5K.get_rate(e['rate']))
          end
          if !(e['model'] == 'N/A N/A' and e['unavailable_for_experiment']) # don't include interface model if not available
            e['model'] = 'N/A' if e['model'] == 'N/A N/A'
            desc << 'model: '+ e['model']
          end
          desc << 'driver: ' + e['driver'] if e['driver']
          desc << 'SR-IOV enabled' if e['sriov'] and not e['unavailable_for_experiment']
          # Generate final string and then adjust
          s = desc.join(', ')
          if e['no_kavlan']
            s += ' - no KaVLAN'
          elsif e['unavailable_for_experiment']
            s = '<span style="color:grey">' + s + ' - unavailable for experiment</span>'
          elsif e['device'] =~ /eth/
            s += ' [[Advanced_KaVLAN#A_simple_multi_NICs_example|(multi NICs example)]]' if !nic_c.zero?
            nic_c += 1
          end
          s = "\n* " + s
          s
        end.join('<br />')

        hard['gpu_str'] = gpu_description(node_hash, false)
        hard['gpu_str_long'] = gpu_description(node_hash, true)
        mic = node_hash['mic']
        hard['mic_str'] = if mic
                            (mic['mic_count'].to_i == 1 ? '' : mic['mic_count'].to_s + '&nbsp;x&nbsp;') + mic['mic_vendor'].to_s + ' ' + mic['mic_model'].to_s.gsub(' ', '&nbsp;')
                          else
                            ''
                          end
        # Add fpga_str information
        fpga = node_hash['other_devices']
        hard['fpga_str'] = if fpga
                              (fpga['fpga0']['count'].to_i == 1 ? '' : fpga['fpga0']['count'].to_s + '&nbsp;x&nbsp;') + fpga['fpga0']['vendor'].to_s + ' ' + fpga['fpga0']['model'].to_s.gsub(' ', '&nbsp;')
                            else
                              ''
                            end
        hard['accelerators'] = hard['gpu_str'] != '' ? hard['gpu_str'] + (hard['mic_str'] != '' ? ' ; ' + hard['mic_str'] : '') : hard['mic_str']
        hard['accelerators'] += hard['fpga_str'] if hard['fpga_str'] != ''

        hard['accelerators_long'] = hard['gpu_str_long'] != '' ? hard['gpu_str_long'] + (hard['fpga_str'] != '' ? ' ; ' + hard['fpga_str'] : '') : hard['fpga_str']
        hard['accelerators_long'] += ' ; ' + hard['mic_str'] if hard['mic_str'] != ''
        add(hardware[site_uid][cluster_uid], node_uid, hard)
      }
    }
  }
  hardware
end

# This method returns a processor family if the architecture/platform_stream is not mainstream
def get_exotic_archname(platform_type)
  case platform_type
  when /aarch64/
    "ARM"
  when /ppc64le/
    "Power"
  else
    nil
  end
end

# This methods adds the array hard to the hash
# hardware. If nodes 2,3,7 have the same hard, they
# will be gathered in the same key and we will have
# hardware[[2,3,7]] = hard
def add(hardware, node_uid, hard)
  num1 = node_uid.split('-')[1].to_i
  if hardware.has_value?(hard) == false
    hardware[[num1]] = hard
  else
    num2 = hardware.key(hard)
    hardware.delete(num2)
    hardware[num2.push(num1)] = hard
  end
end

def get_network_info(e, all_networks)
  rate = G5K.get_rate(e[0]['rate'])
  if e[0]['sriov']
    sriov = "&nbsp;(SR&#8209;IOV)"
  else
    sriov = ''
  end
  (e[1] == 1 ? '' : e[1].to_s + '&nbsp;x&nbsp;') +
    (rate == '' ? '' : rate + sriov + '&nbsp;') +
    (all_networks ? e[0]['interface'].to_s : get_interface(e[0]['interface'])) +
    (all_networks ? (e[0]['used'] == true ? '' : ' (unused)') : '')
end

def get_interface(interface)
  return interface == 'Ethernet' ? '' : interface
end

# Only execute if the file is run directly
if __FILE__ == $0
  options = WikiGenerator::parse_options

  if (options)
    ret=2
    begin
      ret = true
      generators = options[:sites].map{ |site| SiteHardwareGenerator.new(site.capitalize + ':Hardware', site) }
      generators.each{ |generator|
        ret &= generator.exec(options)
      }
    rescue MediawikiApi::ApiError => e
      puts e, e.backtrace
      ret = 3
    rescue StandardError => e
      puts e, e.backtrace
      ret = 4
    ensure
      exit(ret)
    end
  end
end
