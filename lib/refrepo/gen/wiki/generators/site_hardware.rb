# coding: utf-8

require 'refrepo/gpu_ref'

class SiteHardwareGenerator < WikiGenerator

  def initialize(page_name, site)
    super(page_name)
    @site = site
  end

  def generate_content
    has_reservable_disks = false
    G5K::get_global_hash['sites'][@site]['clusters'].each do |_,c|
      c['nodes'].each do |_,n|
        n['storage_devices'].each do |d|
          has_reservable_disks ||= d['reservation']
        end
      end
    end

    @generated_content = "__NOTOC__\n__NOEDITSECTION__\n" +
      "{{Portal|User}}\n" +
      "<div class=\"sitelink\">Hardware: [[Hardware|Global]] | " + G5K::SITES.map { |e| "[[#{e.capitalize}:Hardware|#{e.capitalize}]]" }.join(" | ") + "</div>\n" +
      "'''See also:''' [[#{@site.capitalize}:Network|Network topology for #{@site.capitalize}]]\n" +
      "\n= Summary =\n" +
      "'''#{generate_oneline_summary}'''\n" +
      self.class.generate_summary(@site, false) +
      (has_reservable_disks ? "''*: disk is [[Disk_reservation|reservable]]''" : '') +
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
    MW.generate_table('class="wikitable sortable"', table_columns, table_data) + "\n"
  end

  def generate_oneline_summary
    h = G5K::get_global_hash['sites'][@site]
    # remove retired nodes
    # FIXME this should probably move to a helper
    h['clusters'].each_pair do |cl, v|
      v['nodes'].delete_if { |n, v2| v2['status'] == 'retired' }
    end
    h['clusters'].delete_if { |k, v| v['nodes'].empty? }

    clusters = h['clusters'].length
    nodes = h['clusters'].inject(0) { |a, b| a + b[1]['nodes'].values.length }
    cores = h['clusters'].inject(0) { |a, b| cnodes = b[1]['nodes'].values ; a + cnodes.length * cnodes.first['architecture']['nb_cores'] }
    flops = h['clusters'].inject(0) { |a, b| cnodes = b[1]['nodes'].values ; a + cnodes.length * (cnodes.first['performance']['node_flops'] rescue 0) }
    tflops = sprintf("%.1f", flops.to_f / (10**12))
    return "#{clusters} cluster#{clusters > 1 ? 's' : ''}, #{nodes} node#{nodes > 1 ? 's' : ''}, #{cores} core#{cores > 1 ? 's' : ''}, #{tflops} TFLOPS"
  end

  def self.generate_summary(site, with_sites)
    table_columns, table_data = self.generate_summary_data(site, with_sites)
    MW.generate_table('class="wikitable sortable"', table_columns, table_data) + "\n"
  end

  def self.generate_summary_data(site, with_sites)
    table_columns = []
    table_data = []

    hardware = get_hardware([site])

    site_accelerators = 0
    hardware[site].sort.to_h.each { |cluster_uid, cluster_hash|
      site_accelerators += cluster_hash.select { |k, v| v['accelerators'] != '' }.count
    }

    hardware[site].sort.to_h.each { |cluster_uid, cluster_hash|
      cluster_nodes = cluster_hash.keys.flatten.count
      queue = cluster_hash.map { |k, v| v['queue']}.first
      access_conditions = []
      if queue == 'production'
        access_conditions << "<b>[[Grid5000:UsagePolicy#Rules_for_the_production_queue|#{queue}]]</b>&nbsp;queue"
      elsif queue != ''
        access_conditions << "<b>#{queue}</b>&nbsp;queue"
      end
      access_conditions << '<b>[[Getting_Started#Selecting_specific_resources|exotic]]</b>&nbsp;job&nbsp;type' if cluster_hash.map { |k, v| v['exotic']}.first
      table_columns = (with_sites == true ? ['Site'] : []) + ['Cluster',  'Access Condition', 'Date of arrival', { attributes: 'data-sort-type="number"', text: 'Nodes' }, 'CPU', { attributes: 'data-sort-type="number"', text: 'Cores' }, { attributes: 'data-sort-type="number"', text: 'Memory' }, { attributes: 'data-sort-type="number"', text: 'Storage' }, { attributes: 'data-sort-type="number"', text: 'Network' }] + ((site_accelerators.zero? && with_sites == false) ? [] : ['Accelerators'])
      data = partition(cluster_hash)
      table_data <<  (with_sites == true ? ["[[#{site.capitalize}:Hardware|#{site.capitalize}]]"] : []) + [
        (with_sites == true ? "[[#{site.capitalize}:Hardware##{cluster_uid}" + "|#{cluster_uid}]]" : "[[##{cluster_uid}" + "|#{cluster_uid}]]"),
        access_conditions.join(",<br/>"),
        cell_data(data, 'date'),
        cluster_nodes,
        cell_data(data, 'num_processor_model'),
        cell_data(data, 'cores_per_cpu_str'),
        sort_data(data, 'ram_size') + (!data['pmem_size'].nil? ? " + #{cell_data(data, 'pmem_size')} [[PMEM]]" : ''),
        'data-sort-value="' + sort_data(data, 'storage_size') + '"|' + cell_data(data, 'storage'),
        'data-sort-value="' + sort_data(data, 'network_throughput') + '"|' + cell_data(data, 'used_networks')
      ] + ((site_accelerators.zero? && with_sites == false) ? [] : [cell_data(data, 'accelerators')])
    }
    [table_columns, table_data]
  end

  def self.generate_description(site)
    table_columns = []
    text_data = []

    hardware = get_hardware([site])

    site_accelerators = 0
    hardware[site].sort.to_h.each { |cluster_uid, cluster_hash|
      site_accelerators += cluster_hash.select { |k, v| v['accelerators'] != '' }.count
    }

    # Group by queue
    # Alphabetic ordering of queue names matches what we want: "default" < "production" < "testing"
    hardware[site].group_by { |cluster_uid, cluster_hash| cluster_hash.map { |k, v| v['queue']}.first }.sort.each { |queue, clusters|
      queue = (queue.nil? || queue.empty?) ? 'default' : queue
      text_data << "\n= Clusters in #{queue} queue ="
      clusters.sort.to_h.each { |cluster_uid, cluster_hash|
        subclusters = cluster_hash.keys.count != 1
        cluster_nodes = cluster_hash.keys.flatten.count
        cluster_cpus = cluster_hash.map { |k, v| k.count * v['cpus_per_node'] }.reduce(:+)
        cluster_cores = cluster_hash.map { |k, v| k.count * v['cpus_per_node'] * v['cores_per_cpu'] }.reduce(:+)
        queue_str = cluster_hash.map { |k, v| v['queue_str']}.first
        access_conditions = []
        access_conditions << queue_str if queue_str != ''
        access_conditions << "exotic job type" if cluster_hash.map { |k, v| v['exotic']}.first
        table_columns = ['Cluster',  'Queue', 'Date of arrival', { attributes: 'data-sort-type="number"', text: 'Nodes' }, 'CPU', { attributes: 'data-sort-type="number"', text: 'Cores' }, { attributes: 'data-sort-type="number"', text: 'Memory' }, { attributes: 'data-sort-type="number"', text: 'Storage' }, { attributes: 'data-sort-type="number"', text: 'Network' }] + (site_accelerators.zero? ? [] : ['Accelerators'])

        text_data <<  ["\n== #{cluster_uid} ==\n"]
        text_data << ["'''#{cluster_nodes} #{G5K.pluralize(cluster_nodes, 'node')}, #{cluster_cpus} #{G5K.pluralize(cluster_cpus, 'cpu')}, #{cluster_cores} #{G5K.pluralize(cluster_cores, 'core')}" + (subclusters == true ? ",''' split as follows due to differences between nodes " : "''' ") + "([https://public-api.grid5000.fr/stable/sites/#{site}/clusters/#{cluster_uid}/nodes.json?pretty=1 json])"]

        reservation_cmd = "\n{{Term|location=f#{site}|cmd="
        reservation_cmd += "<code class=\"command\">oarsub</code> "
        reservation_cmd += "<code class=\"replace\">-q #{queue}</code> " if queue != 'default'
        reservation_cmd += "<code class=\"replace\">-t exotic</code> " if cluster_hash.map { |k, v| v['exotic']}.first
        reservation_cmd += "<code class=\"env\">-p \"cluster='#{cluster_uid}'\"</code> "
        reservation_cmd += "<code>-I</code>"
        reservation_cmd += "}}\n"
        text_data << "\n'''Reservation example:'''"
        text_data << reservation_cmd

        cluster_hash.sort.to_h.each_with_index { |(num, h), i|
          if subclusters
            subcluster_nodes = num.count
            subcluster_cpus = subcluster_nodes * h['cpus_per_node']
            subcluster_cores = subcluster_nodes * h['cpus_per_node'] * h['cores_per_cpu']
            text_data << "<hr style=\"height:10pt; visibility:hidden;\" />\n" if i != 0 # smaller vertical <br />
            text_data << ["; #{cluster_uid}-#{G5K.nodeset(num)} (#{subcluster_nodes} #{G5K.pluralize(subcluster_nodes, 'node')}, #{subcluster_cpus} #{G5K.pluralize(subcluster_cpus, 'cpu')}, #{subcluster_cores} #{G5K.pluralize(subcluster_cores, 'core')})"]
          end

          accelerators = nil
          if h['gpu_str'] != '' && h['mic_str'] != ''
            accelerators = 'GPU/Xeon Phi'
          elsif h['gpu_str'] != ''
            accelerators = 'GPU'
          elsif h['mic_str'] != ''
            accelerators = 'Xeon Phi'
          end
          hash = {}
          hash['Access condition'] = access_conditions.join(", ") if not access_conditions.empty?
          hash.merge!({
            'Model' => h['model'],
            'Date of arrival' => h['date'],
            'CPU' => h['processor_description'],
            'Memory' => h['ram_size'] + (!h['pmem_size'].nil? ? " + #{h['pmem_size']} [[PMEM]]" : ''),
            'Storage' => h['storage_description'],
            'Network' => h['network_description'],
          })
          hash[accelerators] = h['accelerators_long'] if accelerators
          text_data << MW::generate_hash_table(hash)
        }
      }
    }

    return text_data.join("\n")
  end
end

# Partitioning the hash values
def partition(cluster_hash)
  data = {}
  h1 = {}
  cluster_hash.sort.to_h.each { |num2, h2|
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
  if lgpu
    bymodel = {}
    lgpu.each { |g|
      d = g[1]
      vendor = d['vendor']
      if long_names
        model = d['model']
      else
        model = GPURef.model2shortname(d['model'])
      end
      vm = vendor.to_s + ' ' + model.to_s.gsub(' ', '&nbsp;')
      if bymodel[vm]
        bymodel[vm] += 1
      else
        bymodel[vm] = 1
      end
    }
    res = []
    bymodel.each { |model,count|
      res << (count == 1 ? '' : count.to_s + '&nbsp;x&nbsp;') + model
    }
  else
    res = []
  end
  res.join(", ")
end


def get_hardware(sites)
  global_hash = G5K::get_global_hash
  known_devices_name = ["sda", "sdb", "sdc", "sdd", "sde","sdf", "nvme0n1", "nvme1n1"]

  # Loop over each cluster of the site
  hardware = {}
  global_hash['sites'].sort.to_h.select{ |site_uid, site_hash| sites.include?(site_uid) }.each { |site_uid, site_hash|
    hardware[site_uid] = {}
    site_hash['clusters'].sort.to_h.each { |cluster_uid, cluster_hash|
      hardware[site_uid][cluster_uid] = {}
      cluster_hash.fetch('nodes').sort.each { |node_uid, node_hash|
        node_hash['storage_devices'].map do |d|
          unless known_devices_name.include?(d['device'])
            raise "unknown device name: #{d['device']}, can't sort correctly"
          end
        end
        next if node_hash['status'] == 'retired'
        # map model to vendor (eg: {'SAS5484654' => 'Seagate', 'PX458' => 'Toshiba' ...}
        hard = {}
        queue = cluster_hash['queues'] - ['admin', 'default']
        hard['queue'] = (queue.nil? || queue.empty?) ? '' : queue[0]
        hard['queue_str'] = (queue.nil? || queue.empty?) ? '' : queue[0] + G5K.pluralize(queue.count, ' queue')
        hard['exotic'] = cluster_hash['exotic']
        hard['date'] = Date.parse(cluster_hash['created_at'].to_s).strftime('%Y-%m-%d')
        hard['model'] = cluster_hash['model']
        hard['processor_model'] = [node_hash['processor']['model'], node_hash['processor']['version']].join(' ')
        if node_hash['processor']['other_description'] =~ /@/
          hard['processor_freq'] = node_hash['processor']['other_description'].split('@')[1].strip
        end
        hard['microarchitecture'] = node_hash['processor']['microarchitecture']
        hard['cpus_per_node'] = node_hash['architecture']['nb_procs']
        hard['cpus_per_node_str'] = hard['cpus_per_node'].to_s + '&nbsp;' + G5K.pluralize(hard['cpus_per_node'], 'CPU') + '/node'
        hard['cores_per_cpu'] = node_hash['architecture']['nb_cores'] / hard['cpus_per_node']
        hard['cores_per_cpu_str'] = hard['cores_per_cpu'].to_s + '&nbsp;' + G5K.pluralize(hard['cores_per_cpu'], 'core') + '/CPU'
        hard['num_processor_model'] = (hard['cpus_per_node'] == 1 ? '' : "#{hard['cpus_per_node']}&nbsp;x&nbsp;") + hard['processor_model'].gsub(' ', '&nbsp;')
        hard['processor_description'] = "#{hard['processor_model']} (#{hard['microarchitecture']}#{hard['processor_freq'] ?  ', ' + hard['processor_freq'] : ''}, #{hard['cpus_per_node_str']}, #{hard['cores_per_cpu_str']})"
        hard['ram_size'] = G5K.get_size(node_hash['main_memory']['ram_size'])
        hard['pmem_size'] = G5K.get_size(node_hash['main_memory']['pmem_size']) unless node_hash['main_memory']['pmem_size'].nil?
        storage = node_hash['storage_devices'].sort_by!{ |d| known_devices_name.index(d['device'])}.map { |i| { 'size' => i['size'], 'tech' => i['storage'], 'reservation' => i['reservation'].nil? ? false : i['reservation'] } }
        hard['storage'] = storage.each_with_object(Hash.new(0)) { |data, counts|
          counts[data] += 1
        }.to_a
          .map.with_index { |e, i|
          size = G5K.get_size(e[0]['size'], 'metric')
          if i.zero?
            if e[1] == 1
              "<b>#{size}&nbsp;#{e[0]['tech']}</b>"
            else
              "<b>1&nbsp;x&nbsp;#{size}&nbsp;#{e[0]['tech']}</b>" + ' +&nbsp;' + (e[1] - 1).to_s + "&nbsp;x&nbsp;#{size}&nbsp;#{e[0]['tech']}" + (e[0]['reservation'] ? '[[Disk_reservation|*]]' : '')
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
        hard['storage_description'] = storage_description.sort_by!{ |d| known_devices_name.index(d['device'])}.map { |e|
          has_reservable_disks ||= e['reservation']
          [
            e['count'] > 1 ? "\n*" : '',
            e['id'] + ',',
            G5K.get_size(e['size'],'metric'),
            e['tech'],
            e['interface'],
            e['vendor'],
            e['model'],
            '(dev: /dev/' + e['device'] + (e['reservation'] ? '*' : '')  + ', by-path: ' + (e['path'] || 'MISSING') + ')',
            e['reservation'] ? '[[Disk_reservation|(reservable)]]' : '',
            e['id'] == 'disk0' ? '(primary disk)' : ''
          ].join(' ')
        }.join('<br />')

        if has_reservable_disks
          hard['storage_description'] += "<br /> \n''*: the disk block device name /dev/sd? may vary in deployed environments, prefer referring to the by-path identifier''"
        end

        network = node_hash['network_adapters'].select { |v|
          v['management'] == false &&
          (v['device'] =~ /\./).nil? # exclude PKEY / VLAN interfaces see #9417
        }.map{|v| {
            'rate' => v['rate'],
            'interface' => v['interface'],
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
            desc.append(e['device'])
          else
            desc.append(e['device'] + "/" + e['name'])
          end
          desc.append(e['interface'])

          if !(e['unwired'] and e['unavailable_for_experiment'])
            desc.append('configured rate: ' + (e['unwired'] ? 'n/c' : G5K.get_rate(e['rate'])))
          end
          if !(e['model'] == 'N/A N/A' and e['unavailable_for_experiment']) # don't include interface model if not available
            e['model'] = 'N/A' if e['model'] == 'N/A N/A'
            desc.append('model: '+ e['model'])
          end
          desc.append('driver: ' + e['driver']) if e['driver']
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
        hard['accelerators'] = hard['gpu_str'] != '' ? hard['gpu_str'] + (hard['mic_str'] != '' ? ' ; ' + hard['mic_str'] : '') : hard['mic_str']
        hard['accelerators_long'] = hard['gpu_str_long'] != '' ? hard['gpu_str_long'] + (hard['mic_str'] != '' ? ' ; ' + hard['mic_str'] : '') : hard['mic_str']

        add(hardware[site_uid][cluster_uid], node_uid, hard)
      }
    }
  }
  hardware
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
  (e[1] == 1 ? '' : e[1].to_s + '&nbsp;x&nbsp;') +
    (rate == '' ? '' : rate + '&nbsp;') +
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
