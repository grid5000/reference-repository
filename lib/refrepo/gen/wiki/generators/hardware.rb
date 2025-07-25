# coding: utf-8
require 'refrepo/gen/wiki/generators/site_hardware'

class G5KHardwareGenerator < WikiGenerator

  def generate_content(_options)
    @global_hash = get_global_hash
    @site_uids = G5K::SITES

    @generated_content = "__NOEDITSECTION__\n"
    @generated_content += "{{Portal|User}}\n"
    @generated_content += "<div class=\"sitelink\">Hardware: [[Hardware|Global]] | " + G5K::SITES.map { |e| "[[#{e.capitalize}:Hardware|#{e.capitalize}]]" }.join(" | ") + "</div>\n"
    @generated_content += SiteHardwareGenerator.generate_header_summary(@global_hash['sites'])
    @generated_content += "\n= Clusters =\n"
    @generated_content += SiteHardwareGenerator.generate_all_clusters
    @generated_content += generate_totals
    @generated_content += MW.italic(MW.small(generated_date_string))
    @generated_content += MW::LINE_FEED
  end

  def generate_totals
    data = {
      'proc_architectures' => {},
      'core_architectures' => {},
      'proc_families' => {},
      'core_families' => {},
      'proc_models' => {},
      'core_models' => {},
      'ram_size' => {},
      'pmem_size' => {},
      'net_interconnects' => {},
      'net_models' => {},
      'ssd_models' => {},
      'acc_families' => {},
      'acc_models' => {},
      'gpu_cores' => {},
      'node_models' => {}
    }

    @global_hash['sites'].sort.to_h.each { |site_uid, site_hash|
      site_hash.fetch('clusters', {}).sort.to_h.each { |_cluster_uid, cluster_hash|
        cluster_hash['nodes'].sort.to_h.each { |node_uid, node_hash|
          begin
            next if node_hash['status'] == 'retired'
            @node = node_uid

            # Processors
            vendor = node_hash['processor']['vendor']
            model = node_hash['processor']['model'].gsub(/^#{vendor} /, '')
            version = node_hash['processor']['version']
            architecture = node_hash['architecture']['platform_type']
            proc_desc = "#{model}"
            if version != 'Unknown'
              proc_desc += " #{version}"
            end
            microarchitecture = node_hash['processor']['microarchitecture']

            cluster_procs = node_hash['architecture']['nb_procs']
            cluster_cores = node_hash['architecture']['nb_cores']

            key = [architecture]
            init(data, 'proc_architectures', key)
            data['proc_architectures'][key][site_uid] += cluster_procs

            init(data, 'core_architectures', key)
            data['core_architectures'][key][site_uid] += cluster_cores

            key = [vendor, model, { text: architecture, sort: architecture }]
            init(data, 'proc_families', key)
            data['proc_families'][key][site_uid] += cluster_procs

            init(data, 'core_families', key)
            data['core_families'][key][site_uid] += cluster_cores

            key = [vendor, {text: proc_desc, sort: get_date(microarchitecture) + ', ' + proc_desc.to_s}, {text: microarchitecture || ' ', sort: get_date(microarchitecture) + ', ' + microarchitecture.to_s}, { text: architecture, sort: architecture }]
            init(data, 'proc_models', key)
            data['proc_models'][key][site_uid] += cluster_procs

            init(data, 'core_models', key)
            data['core_models'][key][site_uid] += cluster_cores

            # RAM size
            ram_size = node_hash['main_memory']['ram_size']
            key = [{ text: G5K.get_size(ram_size), sort: (ram_size / 2**30).to_s.rjust(6, '0') + ' GB' }]
            init(data, 'ram_size', key)
            data['ram_size'][key][site_uid] += 1

            # PMEM size
            if node_hash['main_memory']['pmem_size']
              pmem_size = node_hash['main_memory']['pmem_size']
              key = [{ text: G5K.get_size(pmem_size), sort: (pmem_size / 2**30).to_s.rjust(6, '0') + ' GB' }]
              init(data, 'pmem_size', key)
              data['pmem_size'][key][site_uid] += 1
            end

            # HPC Networks
            interfaces = node_hash['network_adapters'].select{ |v|
              v['enabled'] and
                (v['mounted'] or v['mountable']) and
                not v['management'] and
                (v['device'] =~ /\./).nil? # exclude PKEY / VLAN interfaces see #9417
            }.map{ |v|
              [
                {
                  text: v['interface'] + ' ' + G5K.get_rate(v['rate']),
                  sort: v['interface'] + ' ' +  G5K.get_rate(v['rate'], :sortable)
                }
              ]
            }

            net_interconnects = interfaces.inject(Hash.new(0)){ |h, v| h[v] += 1; h }
            net_interconnects.sort_by { |k, _v|  k.first[:sort] }.each { |k, v|
              init(data, 'net_interconnects', k)
              data['net_interconnects'][k][site_uid] += v
            }

            # NIC models
            interfaces = node_hash['network_adapters'].select{ |v|
              v['enabled'] and
                (v['mounted'] or v['mountable']) and
                not v['management'] and
                (v['device'] =~ /\./).nil? # exclude PKEY / VLAN interfaces see #9417
            }.map{ |v|
              t = (v['vendor'] || 'N/A') + ' ' + (v['model'] || 'N/A');
              [
                {
                  text: v['interface'],
                  sort: v['interface']
                },
                {
                  text: v['driver'], sort: v['driver']
                },
                {
                  text: t, sort: t
                }
              ]
            }.uniq

            net_models = interfaces.inject(Hash.new(0)){ |h, v| h[v] += 1; h }
            # Sort by interface type (eth or IB) and then by driver
            net_models.sort_by { |k, _v|  [k.first[:sort], k[1][:sort]] }.each { |k, v|
              if k.first[:text] == "FPGA/Ethernet"
                k.first[:text] = k.first[:text] + "*"
              end

              init(data, 'net_models', k)
              data['net_models'][k][site_uid] += v
            }

            # NVMe SSD models
            ssd = node_hash['storage_devices'].select{ |v|
              v['storage'] == 'SSD'}.map{ |v|
              t = v['alt_model_name'] || v['model'] || 'N/A';
              # Add vendor if not already there
              if not t.downcase.start_with?(v['vendor'].downcase)
                t = "#{v['vendor']} #{t}"
              end
              [
                {
                  text: v['interface'], sort: v['interface']
                },
                {
                  text: t, sort: t
                },
                {
                  text: G5K.get_size(v['size'], 'metric'), sort: v['size']
                },
              ]
            }

            ssd_models = ssd.inject(Hash.new(0)){ |h, v| h[v] += 1; h }
            ssd_models.sort_by { |k, _v|  k.first[:sort] }.each { |k, v|
              init(data, 'ssd_models', k)
              data['ssd_models'][k][site_uid] += v
            }

           # Accelerators
            { GPU: node_hash.has_key?('gpu_devices') ? node_hash['gpu_devices'] : {},
              MIC: node_hash.has_key?('mic') ? {'mic0': node_hash['mic'] } : {},
              FPGA: node_hash.has_key?('other_devices') ? node_hash['other_devices'].select{ |k,_| k =~ /^fpga\d+$/ } : {}
            }.each do |acc_type, acc_data|
              acc_data.each_value do |acc|
                case acc_type
                when :GPU
                  vendor = acc['vendor']
                  model = GPURef.model2shortname(acc['model'])
                  cores = acc['cores']
                  compute_capability = acc.has_key?('compute_capability') ? acc['compute_capability'] : "N/A"
                  microarchitecture = acc['microarchitecture']
                  mem = RefRepo::Utils.get_as_gb(acc['memory'])
                when :MIC
                  vendor = acc['mic_vendor']
                  model = acc['mic_model']
                  compute_capability = "N/A"
                  microarchitecture = 'N/A'
                  mem = RefRepo::Utils.get_as_gb(acc['mic_memory'])
                when :FPGA
                  vendor = acc['vendor']
                  model = acc['model']
                  compute_capability = "N/A"
                  microarchitecture = 'N/A'
                  mem = RefRepo::Utils.get_as_gb(acc['memory'])
                end

                key = [vendor, { text: acc_type.to_s, sort: acc_type.to_s } ]
                init(data, 'acc_families', key)
                data['acc_families'][key][site_uid] += 1

                key = [vendor,
                       { text: acc_type.to_s, sort: acc_type.to_s },
                       model,
                       {text: microarchitecture, sort: get_date(microarchitecture) + ', ' + microarchitecture},
                       {text: "#{mem}GB", sort: mem },
                       {text: compute_capability, sort: (compute_capability == 'N/A' ? 0 : compute_capability.gsub('.', ', ')) }
                ]
                init(data, 'acc_models', key)
                data['acc_models'][key][site_uid] += 1

                if acc_type == :GPU
                  key = [
                    vendor,
                    model,
                    {text: microarchitecture, sort: get_date(microarchitecture) + ', ' + microarchitecture},
                    {text: "#{mem}GB", sort: mem },
                    {text: compute_capability, sort: (compute_capability == 'N/A' ? 0 : compute_capability.gsub('.', ', ')) }
                  ]
                  init(data, 'gpu_cores', key)
                  data['gpu_cores'][key][site_uid] += cores
                end
              end
            end

            key = [cluster_hash['model']]
            init(data, 'node_models', key)
            data['node_models'][key][site_uid] += 1
          rescue
            puts "ERROR while processing #{node_uid}: #{$!}"
            raise
          end
        }
      }
    }

    # Table construction
    sites = @site_uids.map{ |e| "[[#{e.capitalize}:Hardware|#{e.capitalize}]]" }
    table_options = 'class="wikitable sortable" style="text-align: center;"'
    generated_content = "= CPUs ="
    generated_content += "\n== CPU counts per architecture ==\n"
    table_columns = ['Arch'] + sites + ['CPU total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'proc_architectures'))
    generated_content += "\n== Core counts per architecture ==\n"
    table_columns = ['Arch'] + sites + ['Core total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'core_architectures'))
    generated_content += "\n== CPU counts per family ==\n"
    table_columns = ['Vendor', 'Family', 'Arch'] + sites + ['CPU total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'proc_families'))
    generated_content += "\n== Core counts per family ==\n"
    table_columns = ['Vendor', 'Family', 'Arch'] + sites + ['Core total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'core_families'))
    generated_content += "\n== CPU counts per model ==\n"
    table_columns = ['Vendor', 'Model', 'Microarch', 'Arch'] + sites + ['CPU total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'proc_models'))
    generated_content += "\n== Core counts per model ==\n"
    table_columns =  ['Vendor', 'Model', 'Microarch', 'Arch'] + sites + ['Cores total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'core_models'))

    generated_content += "\n= Memory =\n"
    generated_content += "\n== RAM size per node ==\n"
    table_columns = ['RAM size'] + sites + ['Nodes total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'ram_size'))
    generated_content += "\n== PMEM size per node ==\n"
    table_columns = ['PMEM size'] + sites + ['Nodes total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'pmem_size'))

    generated_content += "\n= Accelerators (GPU, Xeon Phi, FPGA) ="
    generated_content += "\n== Accelerator counts per type ==\n"
    table_columns = ['Vendor', 'Type'] + sites + ['Accelerators total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'acc_families'))
    table_columns = ['Vendor', 'Type', 'Model', 'Microarch', 'Memory', 'Compute capability'] + sites + ['Accelerators total']
    generated_content += "\n== Accelerator counts per model ==\n"
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'acc_models'))
    generated_content += "\n== GPU core counts per GPU model ==\n"
    table_columns = ['Vendor', 'Model', 'Microarch', 'Memory', 'Compute capability'] + sites + ['Cores total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'gpu_cores'))

    generated_content += "\n= Networking =\n"
    generated_content += "\n== Network interconnects ==\n"
    table_columns = ['Interconnect'] + sites + ['Cards total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'net_interconnects'))
    generated_content += "\n== Nodes with several Ethernet interfaces ==\n"
    generated_content +=  generate_interfaces
    generated_content += "\n== Nodes with SR-IOV support ==\n"
    generated_content +=  generate_sriov_interfaces
    generated_content += "\n== Network interface models ==\n"
    table_columns = ['Type', 'Driver', 'Model'] + sites + ['Cards total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'net_models'))
    generated_content += "\n''*: Ethernet interfaces on FPGA cards are not directly usable by the operating system''"

    generated_content += "\n= Storage ="
    generated_content += "\n== SSD models ==\n"
    table_columns = ['SSD interface', 'Model', 'Size'] + sites + ['SSDs total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'ssd_models'))
    generated_content += "\n== Nodes with several disks ==\n"
    generated_content +=  generate_storage
    generated_content += "\n''*: disk is [[Disk_reservation|reservable]]''"

    generated_content += "\n= Nodes models =\n"
    table_columns = ['Nodes model'] + sites + ['Nodes total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'node_models'))
    return generated_content
  end

  def init(data, key1, key2)
    if not data[key1].key?(key2)
      data[key1][key2] = {}
      @site_uids.each { |s| data[key1][key2][s] = 0 }
    end
  end

  # This method generates a wiki table from data[key] values, sorted by key
  # values in first column.
  def get_table_data(data, key)
    raw_data = []
    table_data = []
    index = 0
    k0 = 0
    data[key].sort_by{
      # Sort the table by the identifiers (e.g. Microarchitecture, or Microarchitecture + CPU name).
      # This colum is either just a text field, or a more complex hash with a :sort key that should be
      # used for sorting.
      |k, _v| k.map { |c| c.kind_of?(Hash) ? c[:sort] : c }
    }.to_h.each { |k, v|
      k0 = k if index == 0
      index += 1
      elts = v.sort.to_h.values
      raw_data << elts
      table_data << k.map{ |e| e.kind_of?(Hash) ? "data-sort-value=\"#{e[:sort]}\"|#{e[:text]}" : "data-sort-value=\"#{index.to_s.rjust(3, '0')}\"|#{e}" } +
        elts.map{ |e| e.kind_of?(Hash) ? "data-sort-value=\"#{e[:sort]}\"|#{e[:text]}" : e }
        .map{ |e| e == 0 ? '' : e  } + ["'''#{elts.reduce(:+)}'''"]
    }
    elts = raw_data.transpose.map{ |e| e.reduce(:+)}
    table_data << {columns: ["'''Sites total'''"] +
                   [' '] * (k0.length - 1) +
                   (elts + [elts.reduce(:+)]).map{ |e| e == 0 ? '' : "'''#{e}'''" },
                   sort: false}
  end

  # See: https://en.wikipedia.org/wiki/List_of_Intel_Xeon_microprocessors
  # For a correct sort of the column, all dates must be in the same
  # format (same number of digits)
  def get_date(microarchitecture)
    return 'MISSING' if microarchitecture.nil?
    release_dates = {
      'K8' => '2003',
      'K10' => '2007',
      'Clovertown' => '2006',
      'Harpertown' => '2007',
      'Dunnington' => '2008',
      'Lynnfield' => '2009',
      'Nehalem' => '2010',
      'Westmere' => '2011',
      'Sandy Bridge' => '2012',
      'Ivy Bridge' => '2015',
      'Haswell' => '2013',
      'POWER8' => '2014',
      'Broadwell' => '2015',
      'Skylake-SP' => '2017',
      'Zen' => '2017',
      'Zen 2' => '2019',
      'Zen 3' => '2020',
      'Zen 4' => '2022',
      'Zen 4c' => '2022',
      'Cascade Lake-SP' => '2019',
      'Vulcan' => '2018',
      'Ice Lake-SP' => '2021',
      'Carmel' => '2018',
      'Vega20' => '2018',
      'Ampere' => '2020',
      'Ada Lovelace' => '2022',
      'Turing' => '2018',
      'Maxwell' => '2014',
      'Kepler' => '2012',
      'Pascal' => '2016',
      'Volta' => '2017',
      'Fermi' => '2010',
      'Golden Cove' => '2021',
      'Grace' => '2022',
      'Aldebaran' => '2022',
      'Hopper' => '2022',
      'Sapphire Rapids' => '2023',
      'Emerald Rapids' => '2023',
      'Aqua Vanjaram' => '2023',
      'Sierra Forest' => '2024',
      'N/A' => '&nbsp;',
    }
    date = release_dates[microarchitecture]
    raise "ERROR: microarchitecture not found: '#{microarchitecture}'. Add in hardware.rb" if date.nil?
    date
  end

  def generate_storage
    table_columns = ["Site", "Cluster", "Number of nodes", "Main disk", "Additional HDDs", "Additional SSDs"]
    table_data = []
    global_hash = get_global_hash

    # Loop over Grid'5000 sites
    global_hash["sites"].sort.to_h.each do |site_uid, site_hash|
      site_hash.fetch("clusters", {}).sort.to_h.each do |cluster_uid, cluster_hash|
        nodes_data = []
        cluster_hash.fetch('nodes').sort.to_h.each do |node_uid, node_hash|
          next if node_hash['status'] == 'retired'
          sd = node_hash['storage_devices']
          reservable_disks = sd.select{ |v| v['reservation'] == true }.count > 0
          maindisk = sd.select { |v| v['id'] == 'disk0' }[0]
          maindisk_t = maindisk['storage'] + ' ' + G5K.get_size(maindisk['size'],'metric')
          other = sd.select { |d| d['id'] != 'disk0' }
          hdds = other.select { |d| d['storage'] == 'HDD' }
          if hdds.count == 0
            hdd_t = "0"
          else
            hdd_t = hdds.count.to_s + " (" + hdds.map { |d|
              G5K.get_size(d['size'],'metric') +
              ((!d['reservation'].nil? && d['reservation']) ? '[[Disk_reservation|*]]' : '')
            }.join(', ') + ")"
          end
          ssds = other.select { |d| d['storage'] == 'SSD' }
          if ssds.count == 0
            ssd_t = "0"
          else
            ssd_t = ssds.count.to_s + " (" + ssds.map { |d|
              G5K.get_size(d['size'],'metric') +
              ((!d['reservation'].nil? && d['reservation']) ? '[[Disk_reservation|*]]' : '')
            }.join(', ') + ")"
          end
          nodes_data << { 'uid' => node_uid, 'data' => { 'main' => maindisk_t, 'hdd' => hdd_t, 'ssd' => ssd_t, 'reservation' => reservable_disks } }
        end
        nd = nodes_data.group_by { |d| d['data'] }
        nd.each do |data, nodes|
          # only keep nodes with more than one disk
          next if data['hdd'] == "0" and data['ssd'] == "0"
          if nd.length == 1
            nodesetname = cluster_uid
          else
            nodesetname = cluster_uid + '-' + G5K.nodeset(nodes.map { |n| n['uid'].split('-')[1].to_i })
          end
          table_data << [
            "[[#{site_uid.capitalize}:Hardware|#{site_uid.capitalize}]]",
              "[[#{site_uid.capitalize}:Hardware##{cluster_uid}|#{nodesetname}]]",
              nodes.length,
              data['main'],
              data['hdd'],
              data['ssd'],
          ]
        end
      end
    end
    # Sort by site and cluster name
    table_data.sort_by! { |row|
      [row[0], row[1]]
    }

    # Table construction
    table_options = 'class="wikitable sortable" style="text-align: center;"'
    return MW.generate_table(table_options, table_columns, table_data)
  end

  def generate_interfaces
    table_data = []
    @global_hash["sites"].sort.to_h.each { |site_uid, site_hash|
      site_hash.fetch("clusters", {}).sort.to_h.each { |cluster_uid, cluster_hash|
        network_interfaces = {}
        cluster_hash.fetch('nodes').sort.to_h.each { |node_uid, node_hash|
          next if node_hash['status'] == 'retired'
          if node_hash['network_adapters']
            node_interfaces = node_hash['network_adapters'].select{ |v|
              v['interface'] == 'Ethernet' and
              v['enabled'] == true and
              (v['mounted'] == true or v['mountable'] == true) and
              v['management'] == false
            }

            interfaces = {}
            interfaces['25g_count'] = node_interfaces.select { |v| v['rate'] == 25_000_000_000 }.count
            interfaces['10g_count'] = node_interfaces.select { |v| v['rate'] == 10_000_000_000 }.count
            interfaces['1g_count'] = node_interfaces.select { |v| v['rate'] == 1_000_000_000 }.count
            interfaces['details'] = node_interfaces.map{ |v| v['name'] + ' (' + G5K.get_rate(v['rate']) + ')' }.sort.join(', ')
            queues = cluster_hash['queues'] - ['admin', 'default', 'testing']
            interfaces['queues'] = (queues.nil? || (queues.empty? ? '' : queues[0] + G5K.pluralize(queues.count, ' queue')))
            interface_add(network_interfaces, node_uid, interfaces) if node_interfaces.count > 1
          end
        }

        # One line for each group of nodes with the same interfaces
        network_interfaces.sort.to_h.each { |num, interfaces|
          table_data << [
            "[[#{site_uid.capitalize}:Network|#{site_uid.capitalize}]]",
            "[[#{site_uid.capitalize}:Hardware##{cluster_uid}" + "|#{cluster_uid}" + (network_interfaces.size==1 ? '' : '-' + G5K.nodeset(num)) + "]]",
            num.count,
            interfaces['25g_count'].zero? ? '' : interfaces['25g_count'],
            interfaces['10g_count'].zero? ? '' : interfaces['10g_count'],
            interfaces['1g_count'].zero? ? '' : interfaces['1g_count'],
            interfaces['details']
          ]
        }
      }
    }
    # Sort by site and cluster name
    table_data.sort_by! { |row|
      [row[0], row[1]]
    }

    table_options = 'class="wikitable sortable" style="text-align: center;"'
    table_columns = ["Site", "Cluster", "Nodes", "25G interfaces", "10G interfaces", "1G interfaces", "Interfaces (throughput)"]
    MW.generate_table(table_options, table_columns, table_data)
  end

  def generate_sriov_interfaces
    table_data = []
    @global_hash["sites"].sort.to_h.each { |site_uid, site_hash|
      site_hash.fetch("clusters", {}).sort.to_h.each { |cluster_uid, cluster_hash|
        network_interfaces = {}
        cluster_hash.fetch('nodes').sort.to_h.each { |node_uid, node_hash|
          next if node_hash['status'] == 'retired'
          if node_hash['network_adapters']
            node_interfaces = node_hash['network_adapters'].select{ |v|
              v['sriov'] and
              v['enabled'] == true and
              (v['mounted'] == true or v['mountable'] == true) and
              v['management'] == false
            }

            interfaces = {}
            interfaces['details'] = node_interfaces.map{ |v| v['name'] + " (#{v['sriov_totalvfs']} VFs)" }.sort.join(', ')
            interfaces['vfs_sum'] = node_interfaces.map{ |v| v['sriov_totalvfs'] }.inject(0,:+)
            interface_add(network_interfaces, node_uid, interfaces) if node_interfaces.count > 0
          end
        }

        # One line for each group of nodes with the same interfaces
        network_interfaces.sort.to_h.each { |num, interfaces|
          table_data << [
            "[[#{site_uid.capitalize}:Network|#{site_uid.capitalize}]]",
            "[[#{site_uid.capitalize}:Hardware##{cluster_uid}" + "|#{cluster_uid}" + (network_interfaces.size==1 ? '' : '-' + G5K.nodeset(num)) + "]]",
            num.count,
            "data-sort-value=\"#{interfaces['vfs_sum']}\"|#{interfaces['details']}"
          ]
        }
      }
    }
    # Sort by site and cluster name
    table_data.sort_by! { |row|
      [row[0], row[1]]
    }

    table_options = 'class="wikitable sortable" style="text-align: center;"'
    table_columns = ["Site", "Cluster", "Nodes", "Interfaces (max number of Virtual Functions)"]
    MW.generate_table(table_options, table_columns, table_data)
  end

  # This methods adds the array interfaces to the hash
  # network_interfaces. If nodes 2,3,7 have the same interfaces, they
  # will be gathered in the same key and we will have
  # network_interfaces[[2,3,7]] = interfaces
  def interface_add(network_interfaces, node_uid, interfaces)
    num1 = node_uid.split('-')[1].to_i
    if network_interfaces.has_value?(interfaces) == false
      network_interfaces[[num1]] = interfaces
    else
      num2 = network_interfaces.key(interfaces)
      network_interfaces.delete(num2)
      network_interfaces[num2.push(num1)] = interfaces
    end
  end
end
