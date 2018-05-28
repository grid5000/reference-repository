$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), 'lib')))
require 'wiki_generator'

class CPUParametersGenerator < WikiGenerator

  def initialize(page_name)
    super(page_name)
  end

  def generate_content

    table_columns = ["Installation date", "Site", "Cluster", "CPU Family", "CPU Version", "Microarchitecture", "Frequency", "Server type", "HT enabled", "Turboboost enabled", "P-State driver", "C-State driver"]
    table_data = []
    global_hash = get_global_hash

    # Loop over Grid'5000 sites
    global_hash["sites"].sort.to_h.each { |site_uid, site_hash|
      site_hash.fetch("clusters").sort.to_h.each { |cluster_uid, cluster_hash|

        node_hash = cluster_hash.fetch('nodes').first[1]

        cpu_family = node_hash["processor"]["model"] rescue ""
        cpu_version = node_hash["processor"]["version"] rescue ""
        cpu_freq = node_hash["processor"]["clock_speed"] / 1000000000.0 rescue 0.0 #GHz
        cpu_codename = node_hash["processor"]["microarchitecture"] rescue ""
        ht_enabled = node_hash["bios"]["configuration"]["ht_enabled"] rescue false
        turboboost_enabled = node_hash["bios"]["configuration"]["turboboost_enabled"] rescue false
        pstate_driver = node_hash["operating_system"]["pstate_driver"] rescue ""
        cstate_driver = node_hash["operating_system"]["cstate_driver"] rescue ""

        #One line per cluster
        table_data << [
          DateTime.new(*cluster_hash["created_at"].to_s.scan(/\d+/).map {|i| i.to_i}).strftime("%Y-%m-%d"),
          site_uid,
          cluster_uid,
          cpu_family,
          cpu_version,
          cpu_codename,
          cpu_freq.to_s + " GHz",
          cluster_hash["model"],
          ht_enabled ? "{{Yes}}" : "{{No}}",
          turboboost_enabled ? "{{Yes}}" : "{{No}}",
          pstate_driver,
          cstate_driver
        ]
      }
    }
    #Sort by cluster date
    table_data.sort_by! { |row|
      [DateTime.parse(row[0]), row[1], row[2]]
    }

    #Table construction
    table_options = 'class="wikitable sortable" style="text-align: center;"'
    @generated_content = MW.generate_table(table_options, table_columns, table_data)
    @generated_content += MW.italic(MW.small(generated_date_string))
    @generated_content += MW::LINE_FEED
  end
end

if __FILE__ == $0
  generator = CPUParametersGenerator.new("Generated/CPUParameters")

  options = WikiGenerator::parse_options
  if (options)
    ret = 2
    begin
      ret = generator.exec(options)
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
