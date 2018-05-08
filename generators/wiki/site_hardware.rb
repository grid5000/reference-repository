# coding: utf-8
require 'optparse'
require 'date'
require 'pp'

require_relative '../lib/input_loader'
require_relative './wiki_generator'
require_relative './mw_utils'

class SiteHardwareGenerator < WikiGenerator

  def initialize(page_name, site)
    super(page_name)
    @site = site
  end
  
  def generate_content
    @generated_content = "__NOTOC__\n__NOEDITSECTION__\n"
    @generated_content += "<div class=\"sitelink\">[[Hardware|Global]] | " + G5K::SITES.map { |e| "[[#{e.capitalize}:Hardware|#{e.capitalize}]]" }.join(" | ") + "</div>\n"
    @generated_content += "\n= Summary =\n"
    @generated_content += self.class.generate_summary(@site, false)
    @generated_content += self.class.generate_description(@site)
    @generated_content += MW.italic(MW.small('Generated from the Grid5000 APIs on ' + Time.now.strftime('%Y-%m-%d')))
    @generated_content += MW::LINE_FEED
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
      queue_str = cluster_hash.map { |k, v| v['queue_str']}.first
      table_columns = (with_sites == true ? ['Site'] : []) + ['Cluster',  'Queue', 'Date of arrival', { attributes: 'data-sort-type="number"', text: 'Nodes' }, 'CPU', { attributes: 'data-sort-type="number"', text: 'Cores' }, { attributes: 'data-sort-type="number"', text: 'Memory' }, { attributes: 'data-sort-type="number"', text: 'Storage' }, { attributes: 'data-sort-type="number"', text: 'Network' }] + ((site_accelerators.zero? && with_sites == false) ? [] : ['Accelerators'])
      data = partition(cluster_hash)
      table_data <<  (with_sites == true ? ["[[#{site.capitalize}:Hardware|#{site.capitalize}]]"] : []) + [
        (with_sites == true ? "[[#{site.capitalize}:Hardware##{cluster_uid}" + (queue_str == '' ? '' : "_.28#{queue_str.gsub(' ', '_')}.29") + "|#{cluster_uid}]]" : "[[##{cluster_uid}" + (queue_str == '' ? '' : "_.28#{queue_str.gsub(' ', '_')}.29") + "|#{cluster_uid}]]"),
        (queue == '' ? 'default' : queue),
        cell_data(data, 'date'),
        cluster_nodes,
        cell_data(data, 'num_processor_model'),
        cell_data(data, 'cores_per_cpu_str'),
        cell_data(data, 'ram_size'),
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
    
    hardware[site].sort.to_h.each { |cluster_uid, cluster_hash|
      subclusters = cluster_hash.keys.count != 1
      cluster_nodes = cluster_hash.keys.flatten.count
      cluster_cpus = cluster_hash.map { |k, v| k.count * v['cpus_per_node'] }.reduce(:+)
      cluster_cores = cluster_hash.map { |k, v| k.count * v['cpus_per_node'] * v['cores_per_cpu'] }.reduce(:+)
      queue_str = cluster_hash.map { |k, v| v['queue_str']}.first
      table_columns = ['Cluster',  'Queue', 'Date of arrival', { attributes: 'data-sort-type="number"', text: 'Nodes' }, 'CPU', { attributes: 'data-sort-type="number"', text: 'Cores' }, { attributes: 'data-sort-type="number"', text: 'Memory' }, { attributes: 'data-sort-type="number"', text: 'Storage' }, { attributes: 'data-sort-type="number"', text: 'Network' }] + (site_accelerators.zero? ? [] : ['Accelerators'])
      
      text_data <<  ["\n== #{cluster_uid}" + (queue_str == '' ? '' : " (#{queue_str})") + " ==\n"]
      text_data << ["'''#{cluster_nodes} #{G5K.pluralize(cluster_nodes, 'node')}, #{cluster_cpus} #{G5K.pluralize(cluster_cpus, 'cpu')}, #{cluster_cores} #{G5K.pluralize(cluster_cores, 'core')}" + (subclusters == true ? ",''' split as follows due to differences between nodes " : "''' ") + "([https://public-api.grid5000.fr/stable/sites/#{site}/clusters/#{cluster_uid}/nodes.json?pretty=1 json])"]

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
        hash = {
          'Model' => h['model'],
          'Date of arrival' => h['date'],
          'CPU' => h['processor_description'],
          'Memory' => h['ram_size'],
          'Storage' => h['storage_description'],
          'Network' => h['network_description'],
        }
        hash[accelerators] = h['accelerators'] if accelerators
        text_data << MW::generate_hash_table(hash)
      }
    }

    generated_content = "\n= Cluster details =\n"
    generated_content += text_data.join("\n")
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

def get_hardware(sites)
  global_hash = G5K::get_global_hash
  
  # Loop over each cluster of the site
  hardware = {}
  global_hash['sites'].sort.to_h.select{ |site_uid, site_hash| sites.include?(site_uid) }.each { |site_uid, site_hash|
    hardware[site_uid] = {}
    site_hash['clusters'].sort.to_h.each { |cluster_uid, cluster_hash|
      hardware[site_uid][cluster_uid] = {}
      cluster_hash.fetch('nodes').sort.each { |node_uid, node_hash|
        next if node_hash['status'] == 'retired'
        hard = {}
        queue = cluster_hash['queues'] - ['admin', 'default']
        hard['queue'] = (queue.nil? || queue.empty?) ? '' : queue[0]
        hard['queue_str'] = (queue.nil? || queue.empty?) ? '' : queue[0] + G5K.pluralize(queue.count, ' queue')

        hard['date'] = Date.parse(cluster_hash['created_at'].to_s).strftime('%Y-%m-%d')
        hard['model'] = cluster_hash['model']
        hard['processor_model'] = [node_hash['processor']['model'], node_hash['processor']['version']].join(' ')
        hard['processor_freq'] = node_hash['processor']['other_description'].split('@')[1]
        hard['microarchitecture'] = node_hash['processor']['microarchitecture']
        hard['cpus_per_node'] = node_hash['architecture']['nb_procs']
        hard['cpus_per_node_str'] = hard['cpus_per_node'].to_s + '&nbsp;' + G5K.pluralize(hard['cpus_per_node'], 'CPU') + '/node'
        hard['cores_per_cpu'] = node_hash['architecture']['nb_cores'] / hard['cpus_per_node']
        hard['cores_per_cpu_str'] = hard['cores_per_cpu'].to_s + '&nbsp;' + G5K.pluralize(hard['cores_per_cpu'], 'core') + '/CPU'
        hard['num_processor_model'] = (hard['cpus_per_node'] == 1 ? '' : "#{hard['cpus_per_node']}&nbsp;x&nbsp;") + hard['processor_model'].gsub(' ', '&nbsp;')
        hard['processor_description'] = [hard['processor_model'], hard['microarchitecture'], hard['processor_freq'], '(' + hard['cpus_per_node_str'] + ',', hard['cores_per_cpu_str'] + ')'].join(' ')
        hard['ram_size'] = G5K.get_size(node_hash['main_memory']['ram_size'])       
        storage = node_hash['storage_devices'].map{ |k, v| {'size' => v['size'],  'tech' => v['storage']} }
        hard['storage'] = storage.each_with_object(Hash.new(0)) { |data, counts| counts[data] += 1 }.to_a.sort_by { |e| e[0]['size'].to_f }.map{ |e| (e[1] == 1 ? '' : e[1].to_s + '&nbsp;x&nbsp;') + G5K.get_size(e[0]['size']) + '&nbsp;' + e[0]['tech'] }.join(' +&nbsp;')
        hard['storage_size'] = storage.inject(0){|sum, v| sum + (v['size'].to_f / 2**30).floor }.to_s # round to GB to avoid small differences within a cluster
        storage_description = node_hash['storage_devices'].map { |k, v| { 'device' => v['device'], 'size' => v['size'], 'tech' => v['storage'], 'interface' => v['interface'], 'model' => v['model'], 'driver' => v['driver'], 'path' => v['by_path'] || v['by_id'],  'count' => node_hash['storage_devices'].count } }
        hard['storage_description'] = storage_description.map { |e| [ e['count'] > 1 ? "\n*" : '', G5K.get_size(e['size']), e['tech'], e['interface'], e['model'], ' (driver: ' + e['driver'] + ', path: ' + e['path']+ ')'].join(' ') }.join('<br />')
        
        network = node_hash['network_adapters'].select { |k, v| v['management'] == false }.map{ |k, v| {'rate' => v['rate'], 'interface' => v['interface'], 'used' => (v['enabled'] and (v['mounted'] or v['mountable'])) } }
        hard['used_networks'] = network.select { |e| e['used'] == true }.each_with_object(Hash.new(0)) { |data, counts| counts[data] += 1 }.to_a.sort_by{ |e| e[0]['rate'].to_f }.map{ |e| get_network_info(e, false) }.join('+&nbsp;')
        hard['network_throughput'] = network.select { |e| e['used'] == true }.inject(0){|sum, v| sum + (v['rate'].to_f / 10**6).floor }.to_s # round to Mbps
        network_description = node_hash['network_adapters'].select { |k, v| v['management'] == false }.map{ |k, v| { 'device' => k, 'name' => v['name'], 'rate' => v['rate'], 'interface' => v['interface'], 'driver' => v['driver'], 'unwired' => v['enabled'] == false, 'unavailable_for_experiment' => v['mountable'] == false, 'no_kavlan' => (v['interface'] == 'Ethernet' && v['mountable'] == true && v['kavlan'] == false), 'count' => node_hash['network_adapters'].count } }.sort_by{ |e| e['device'] }
        hard['network_description'] = network_description.map { |e| ((e['count'] > 1 ? ["\n*"] : []) + (e['unavailable_for_experiment'] ? ['<span style="color:grey">'] : []) + (e['name'].nil? ? [e['device'] + ','] : [e['device'] + "/" + e['name'] + ',']) + [e['interface'], '(driver: ' + e['driver'] + '),', 'configured rate: ' + (e['unwired'] ? 'n/c' : G5K.get_rate(e['rate'])), ('- unavailable for experiment' if e['unavailable_for_experiment']), ('- no KaVLAN' if e['no_kavlan']), e['unavailable_for_experiment'] ? '</span>' : '']).join(' ') }.join('<br />')

        gpu = node_hash['gpu']
        hard['gpu_str'] = if gpu && gpu['gpu']
                            (gpu['gpu_count'].to_i == 1 ? '' : gpu['gpu_count'].to_s + '&nbsp;x&nbsp;') + gpu['gpu_vendor'].to_s + ' ' + gpu['gpu_model'].to_s.gsub(' ', '&nbsp;')
                          else
                            ''
                          end
        mic = node_hash['mic']
        hard['mic_str'] = if mic
                            (mic['mic_count'].to_i == 1 ? '' : mic['mic_count'].to_s + '&nbsp;x&nbsp;') + mic['mic_vendor'].to_s + ' ' + mic['mic_model'].to_s.gsub(' ', '&nbsp;')
                          else
                            ''
                          end
        hard['accelerators'] = hard['gpu_str'] != '' ? hard['gpu_str'] + (hard['mic_str'] != '' ? ' ; ' + hard['mic_str'] : '') : hard['mic_str']
        
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
        ret &= WikiGenerator::exec(generator, options)
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
