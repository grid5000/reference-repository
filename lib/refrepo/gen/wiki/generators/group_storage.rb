# coding: utf-8

class GroupStorageGenerator < WikiGenerator

  def initialize(page_name)
    super(page_name)
  end

  def generate_content(_options)
    table_columns = ["Site", "Server Name", "Size", "Link Speed", "Notes"]
    table_data = []
    global_hash = get_global_hash

    # Loop over Grid'5000 sites
    global_hash["sites"].sort.to_h.each { |site_uid, site_hash|
      site_hash.fetch("servers").sort.to_h.each_value { |server_hash|
        next unless server_hash['group_storage']
        group_storage = server_hash['group_storage']
        table_data << [
          "[[#{site_uid.capitalize}:Hardware|#{site_uid.capitalize}]]",
          "#{group_storage['name']}.#{site_uid}.grid5000.fr",
          G5K.get_size(group_storage['size'], 'metric'),
          G5K.get_rate(group_storage['rate']),
          group_storage["comment"] || ""
        ]
      }
    }
    # Sort by site and server name
    table_data.sort_by! { |row|
      [row[0], row[1]]
    }

    # Table construction
    table_options = 'class="wikitable sortable" style="text-align: center;"'
    @generated_content = MW.generate_table(table_options, table_columns, table_data)
    @generated_content += MW.italic(MW.small(generated_date_string))
    @generated_content += MW::LINE_FEED
  end
end
