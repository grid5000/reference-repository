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
      'proc_families' => {},
      'proc_models' => {},
      'core_models' => {},
      'ram_size' => {},
      'pmem_size' => {},
      'net_interconnects' => {},
      'net_models' => {},
      'ssd_models' => {},
      'acc_families' => {},
      'acc_models' => {},
      'acc_cores' => {},
      'node_models' => {}
    }

    @global_hash['sites'].sort.to_h.each { |site_uid, site_hash|
      site_hash['clusters'].sort.to_h.each { |_cluster_uid, cluster_hash|
        cluster_hash['nodes'].sort.to_h.each { |node_uid, node_hash|
          begin
            next if node_hash['status'] == 'retired'
            @node = node_uid

            # Processors
            model = node_hash['processor']['model']
            version = "#{model} #{node_hash['processor']['version']}"
            microarchitecture = node_hash['processor']['microarchitecture']

            cluster_procs = node_hash['architecture']['nb_procs']
            cluster_cores = node_hash['architecture']['nb_cores']

            key = [model]
            init(data, 'proc_families', key)
            data['proc_families'][key][site_uid] += cluster_procs

            key = [{text: microarchitecture || ' ', sort: get_date(microarchitecture) + ', ' + microarchitecture.to_s}, {text: version, sort: get_date(microarchitecture) + ', ' + version.to_s}]
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
              if k.first[:text] == "Ethernet-FPGA"
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
            other_dev = node_hash['other_devices']
            fpga_families = {}
            fpga_details = {}
            if other_dev and other_dev['fpga0']
              fpga = other_dev['fpga0']
              vendor_type = "#{fpga['vendor']} #{fpga['type'].upcase}"
              vendor_model = "#{fpga['vendor']} #{fpga['model']}"
              fpga_families[[vendor_type]] = 1
              fpga_details[[vendor_model]] = [fpga['count'], fpga['core']]
            end

            
            m = node_hash['mic']
            mic_families = {}
            mic_details = {}
            if m and m['mic']
              vendor_mic = "#{m['mic_vendor']} MIC"
              vendor_model = "#{m['mic_vendor']} #{m['mic_model']}"
              mic_families[[vendor_mic]] = m['mic_count']
              mic_details[[vendor_model]] = [m['mic_count'], m['mic_cores']]
            end


            lg = node_hash['gpu_devices']
            gpu_families = {}
            gpu_details = {}
            unless lg.nil?
              lg.each { |g|
                d = g[1]
                vendor_families = "#{d['vendor']} GPU"
                vendor = d['vendor']
                cmodel = d['model']
                model = cmodel
                nbcores = GPURef.getNumberOfCoresFor(cmodel)

                family = gpu_families[[vendor_families]]
                if family.nil?
                  gpu_families[[vendor_families]] = 1
                else
                  gpu_families[[vendor_families]] += 1
                end                


                details = gpu_details[["#{vendor} #{model}"]]

                if details.nil?
                  gpu_details[["#{vendor} #{model}"]] = [1, nbcores]
                else
                  gpu_details[["#{vendor} #{model}"]] = [details[0]+1, details[1]+nbcores]
                end
              }
            end

            gpu_families.merge(mic_families).merge(fpga_families).sort.to_h.each { |k, v|
              init(data, 'acc_families', k)
              data['acc_families'][k][site_uid] += v
            }

            gpu_details.merge(mic_details).merge(fpga_details).sort.to_h.each { |k, v|
              init(data, 'acc_models', k)
              data['acc_models'][k][site_uid] += v[0]
            }
            gpu_details.merge(mic_details).sort.to_h.each { |k, v|
              init(data, 'acc_cores', k)
              data['acc_cores'][k][site_uid] += v[1]
            }

            # Nodes
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
    generated_content = "= Processors ="
    generated_content += "\n== Processors counts per families ==\n"
    sites = @site_uids.map{ |e| "[[#{e.capitalize}:Hardware|#{e.capitalize}]]" }
    table_options = 'class="wikitable sortable" style="text-align: center;"'
    table_columns = ['Processor family'] + sites + ['Processors total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'proc_families'))
    generated_content += "\n== Processors counts per models ==\n"
    table_columns = ['Microarchitecture', 'Processor model'] + sites + ['Processors total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'proc_models'))
    generated_content += "\n== Cores counts per models ==\n"
    table_columns =  ['Microarchitecture', 'Core model'] + sites + ['Cores total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'core_models'))

    generated_content += "\n= Memory =\n"
    generated_content += "\n== RAM size per node ==\n"
    table_columns = ['RAM size'] + sites + ['Nodes total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'ram_size'))
    generated_content += "\n== PMEM size per node ==\n"
    table_columns = ['PMEM size'] + sites + ['Nodes total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'pmem_size'))

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
    generated_content += "\n''*: By default network interface on FPGA card is not supported by OS''"
    generated_content += "\n= Storage ="
    generated_content += "\n== SSD models ==\n"
    table_columns = ['SSD interface', 'Model', 'Size'] + sites + ['SSDs total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'ssd_models'))
    generated_content += "\n== Nodes with several disks ==\n"
    generated_content +=  generate_storage
    generated_content += "\n''*: disk is [[Disk_reservation|reservable]]''"

    generated_content += "\n= Accelerators (GPU, Xeon Phi, FPGA) ="
    generated_content += "\n== Accelerator families ==\n"
    table_columns = ['Accelerator family'] + sites + ['Accelerators total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'acc_families'))
    table_columns = ['Accelerator model'] + sites + ['Accelerators total']
    generated_content += "\n== Accelerator models ==\n"
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'acc_models'))
    generated_content += "\n== Accelerator cores ==\n"
    table_columns = ['Accelerator model'] + sites + ['Cores total']
    generated_content += MW.generate_table(table_options, table_columns, get_table_data(data, 'acc_cores'))

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
      'Haswell' => '2013',
      'POWER8' => '2014',
      'Broadwell' => '2015',
      'Skylake' => '2016',
      'Zen' => '2017',
      'Zen 2' => '2019',
      'Cascade Lake-SP' => '2019',
      'Vulcan' => '2018',
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
      site_hash.fetch("clusters").sort.to_h.each do |cluster_uid, cluster_hash|
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
      site_hash.fetch("clusters").sort.to_h.each { |cluster_uid, cluster_hash|
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
      site_hash.fetch("clusters").sort.to_h.each { |cluster_uid, cluster_hash|
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
