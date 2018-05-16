#!/usr/bin/ruby

if RUBY_VERSION < "2.1"
  puts "This script requires ruby >= 2.1"
  exit
end

require 'pp'
require '../lib/input_loader'

# replace default deep_merge before calling load_yaml_file_hierarchy
class ::Hash
  def deep_merge(other_hash)
    # merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }

    merger = proc {|key, v1, v2|
      if Hash === v1 && Hash === v2
        v1.merge(v2, &merger)
      else
        v1.gsub!('!duplicated: ') if String === v1
        v2.gsub!('!duplicated: ') if String === v2
        if Hash === v1 || Hash === v2
          # for example, this occurs if there are some empty entries on yaml files that need to be deleted (ex: parasilo-1 => {})
          # return a hash because it is needed by expand_square_brackets
          {'v1' => v1, 'v2' => v2, 'error' => "!duplicated: #{key}"}
        else
          # remove the following 'if' if you want all the duplicated keys
          #if v1 != v2
          "!duplicated: '#{v1}' '#{v2}'"
          #else
          #  v2
          #end
        end
      end
    }

    self.merge(other_hash, &merger)
  end
end

def yaml_input_find_duplicates(refapi_hash, options)

  refapi_hash["sites"].sort.each do |site_uid, site|
    if options.key?(:sites) && !options[:sites].include?(site_uid)
      refapi_hash["sites"].delete(site_uid)
    end

    site["clusters"].sort.each do |cluster_uid, cluster|
      if options.key?(:clusters) && !options[:clusters].include?(cluster_uid)
          site["clusters"].delete(cluster_uid)
      end
    end
  end

# remove entries that are not duplicate
  refapi_hash.deep_reject! {|k, v| !(
  (v.is_a?(Hash) && !v.empty?) ||
      v.is_a?(String) && v.start_with?('!duplicated:')
  )}

# remove ip, mac and mounted properties (as it can be use to bootstrap the installation of a cluster)
  refapi_hash.deep_reject! {|k, v| k == 'ip' || k == 'mac' || k == 'mounted'}
  refapi_hash.deep_reject! {|k, v| v == {}}

  if refapi_hash.empty?
    puts "OK: no duplicate entries."
  else
    puts refapi_hash.to_yaml
  end

end

if __FILE__ == $0
  require 'optparse'

  options = {}
  options[:sites] = %w{grenoble lille luxembourg lyon nancy nantes rennes sophia}
  options[:api] = {}

  OptionParser.new do |opts|
    opts.banner = "Usage: yaml-input-find-duplicates.rb [options]"

    opts.separator ""
    opts.separator "Example: ruby yaml-input-find-duplicates.rb -v"

    ###

    opts.separator ""
    opts.separator "Filters:"

    opts.on('-s', '--sites a,b,c', Array, 'Select site(s)',
            "Default: "+options[:sites].join(", ")) do |s|
      raise "Wrong argument for -s option." unless (s - options[:sites]).empty?
      options[:sites] = s
    end

    opts.on('-c', '--clusters a,b,c', Array, 'Select clusters(s). Default: all') do |s|
      options[:clusters] = s
    end

    opts.separator ""
    opts.separator "Common options:"

    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      options[:verbose] ||= 0
      options[:verbose] = options[:verbose] + 1
    end

    # Print an options summary.
    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end.parse!

  refapi_hash = load_yaml_file_hierarchy("../../input/grid5000/")
  yaml_input_find_duplicates(refapi_hash, options)
end
