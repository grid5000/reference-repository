require "optparse"
require "mediawiki_api"

require_relative '../lib/input_loader'
require_relative './mw_utils'

options = {}

opt_parse = OptionParser.new do |opts|
  opts.banner = "Usage: cpuParameters.rb --api-user user --api-password password"

  opts.on('-u=user', '--api-user=user', String, 'User for HTTP authentication ') do |user|
    options[:user] = user
  end

  opts.on('-p=pwd', '--api-password=pwd', String, 'Password for HTTP authentication') do |pwd|
    options[:pwd] = pwd
  end
end

opt_parse.parse!

if (options[:user].nil? || options[:pwd].nil?)
  puts opt_parse.to_s
  exit
end

target_page = "Template:CPUParameters"

table_columns = ["Installation date", "Site", "Cluster", "CPU Family", "CPU Version", "Core Codename", "Frequency", "Server type", "HT enabled", "Turboboost enabled", "P-State driver", "C-State driver"]

table_data = []

#Static cluster information not present in the ref-repo
cluster_data = YAML::load_file(File.join(File.dirname(File.expand_path(__FILE__)), 'clusters_data.yml'))

global_hash = load_yaml_file_hierarchy(File.expand_path("../../input/grid5000/", File.dirname(__FILE__)))

# Loop over Grid'5000 sites
global_hash["sites"].each { |site_uid, site_hash|

  site_hash.fetch("clusters").each { |cluster_uid, cluster_hash|

    node_hash = cluster_hash.fetch('nodes').first[1]

    cpu_family = node_hash["processor"]["model"] rescue ""
    cpu_version = node_hash["processor"]["version"] rescue ""
    cpu_freq = node_hash["processor"]["clock_speed"] / 1000000000.0 rescue 0.0 #GHz

    ht_enabled = node_hash["bios"]["configuration"]["ht_enabled"] rescue false
    turboboost_enabled = node_hash["bios"]["configuration"]["turboboost_enabled"] rescue false
    pstate_driver = node_hash["operating_system"]["pstate_driver"] rescue ""
    cstate_driver = node_hash["operating_system"]["cstate_driver"] rescue ""

    cpu_codename = cluster_data[cluster_uid]["cpu_codename"] rescue ""

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
  DateTime.parse(row[0])
}

#Table construction

table_options = 'class="G5KDataTable" border="1" style="text-align: center;"'

page_text = MW.generate_table(table_options, table_columns, table_data)

page_text += MW.italic(MW.small("Generated from the Grid5000 APIs on " + Time.now.strftime("%Y-%m-%d")))

#Finally Create/modify the page on mediawiki
client = MediawikiApi::Client.new(MW::BASE_URL)
client.log_in(options[:user], options[:pwd])
client.edit({"title" => target_page, "text" => page_text })
