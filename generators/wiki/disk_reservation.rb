# coding: utf-8
require_relative '../lib/input_loader'
require_relative './wiki_generator'
require_relative './mw_utils'

class DiskReservationGenerator < WikiGenerator

  def initialize(page_name)
    super(page_name)
  end

  def generate_content
    table_columns = ["Site", "Cluster", "Number of nodes", "Number of reservable disks per node"]
    table_data = []
    global_hash = get_global_hash

    # Loop over Grid'5000 sites
    global_hash["sites"].sort.to_h.each { |site_uid, site_hash|
      site_hash.fetch("clusters").sort.to_h.each { |cluster_uid, cluster_hash|
        disk_info = {}
        cluster_hash.fetch('nodes').sort.to_h.each { |node_uid, node_hash|
          next if node_hash['status'] == 'retired'
           reservable_disks = node_hash['storage_devices'].select{ |k, v| v['reservation'] == true }.count
          add(disk_info, node_uid, reservable_disks)
        }

        # One line for each group of nodes with the same number of reservable disks
        disk_info.sort.to_h.each { |num, reservable_disks|
        table_data << [
          "[[#{site_uid.capitalize}:Hardware|#{site_uid.capitalize}]]",
          "[https://public-api.grid5000.fr/stable/sites/#{site_uid}/clusters/#{cluster_uid}/nodes.json?pretty=1 #{cluster_uid}" + (disk_info.size== 1 ? '' : '-' + G5K.nodeset(num)) + "]",
          num.count,
          reservable_disks
          ] if reservable_disks > 0
        }
      }
    }
    # Sort by site and cluster name
    table_data.sort_by! { |row|
      [row[0], row[1]]
    }

    # Table construction
    table_options = 'class="wikitable sortable"'
    @generated_content = MW.generate_table(table_options, table_columns, table_data)
    @generated_content += MW.italic(MW.small("Generated from the Grid5000 APIs on " + Time.now.strftime("%Y-%m-%d")))
    @generated_content += MW::LINE_FEED
  end

  # This methods adds the array disk to the hash
  # disk_info. If nodes 2,3,7 have the same disk, they
  # will be gathered in the same key and we will have
  # disk_info[[2,3,7]] = disk
  def add(disk_info, node_uid, disk)
    num1 = node_uid.split('-')[1].to_i
    if disk_info.has_value?(disk) == false
      disk_info[[num1]] = disk
    else
      num2 = disk_info.key(disk)
      disk_info.delete(num2)
      disk_info[num2.push(num1)] = disk
    end
  end
end

generator = DiskReservationGenerator.new("Generated/DiskReservation")

options = WikiGenerator::parse_options
if (options)
  ret = 2
  begin
    ret = WikiGenerator::exec(generator, options)
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
