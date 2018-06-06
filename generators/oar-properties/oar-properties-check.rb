#!/usr/bin/ruby
# coding: utf-8

require 'pp'
require 'erb'
require 'fileutils'
require 'pathname'
require 'json'
require 'time'
require 'yaml'
require 'set'
require 'hashdiff'
require 'optparse'
require 'net/ssh'
require 'open-uri'


# Propriétés qui devraient être présentes
G5K_PROPERTIES=%w{api_timestamp available_upto besteffort chunks cluster cluster_priority comment core cpu cpuarch cpucore cpufreq cpuset cputype deploy desktop_computing disk disk_reservation_count diskpath disktype drain eth_count eth_rate expiry_date finaud_decision gpu gpu_count grub host ib ib_count ib_rate id ip last_available_upto last_job_date links maintenance max_walltime memcore memcpu memnode mic myri myri_count myri_rate network_address next_finaud_decision next_state nodemodel production rconsole scheduler_priority slash_16 slash_17 slash_18 slash_19 slash_20 slash_21 slash_22 state state_num subnet_address subnet_prefix suspended_jobs switch type virtual vlan wattmeter}.sort

class Hash
  def slice(*extract)
    h2 = self.select{|key, value| extract.include?(key) }
    h2
  end
end

def parse_command_line_parameters
  options = {}
  options[:sites] = %w(grenoble lille luxembourg lyon nancy nantes rennes sophia)

  OptionParser.new do |opts|
    opts.banner = 'Usage: oar-properties-check.rb [options]'
    opts.separator ''
    opts.separator 'Example: ruby oar-properties-check.rb -v -s nancy'
    opts.separator ''

    opts.separator 'Filters:'
    opts.on('-s', '--sites a,b,c', Array, 'Select site(s)',
            'Default: ' + options[:sites].join(', ')) do |s|
      raise 'Wrong argument for -s option.' unless (s - options[:sites]).empty?
      options[:sites] = s
    end
    opts.on('-c', '--clusters a,b,c', Array, 'Select clusters(s). Default: all') do |s|
      options[:clusters] = s
    end
    opts.separator ''
    opts.separator 'Common options:'
    opts.on('-v', '--[no-]verbose', 'Run verbosely', 'Multiple -v options increase the verbosity. The maximum is 3.') do | |
      options[:verbose] ||= 0
      options[:verbose] = options[:verbose] + 1
    end

    # Print an options summary.
    opts.on_tail('-h', '--help', 'Show this message') do
      puts opts
      exit
    end
  end.parse!

  puts "Options: #{options}" if options[:verbose]

  return options
end

ret = true
options = parse_command_line_parameters

options[:sites].each do |site|
  puts "Checking site #{site}..."
  resources = JSON::parse(open("https://api-proxy.nancy.grid5000.fr/3.0/sites/#{site}/internal/oarapi/resources/details.json?limit=1000000", {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read)['items']

  default_resources = resources.select { |e| e['type'] == 'default' }.sort_by { |e| e['id'] }

  # Checking list of properties
  names = default_resources.map { |e| e.keys.sort }.uniq.first
  if names != G5K_PROPERTIES
    puts "ERROR: wrong list of properties:"
    ret = false
    puts "- " + (G5K_PROPERTIES - names).join(' ')
    puts "+ " + (names - G5K_PROPERTIES).join(' ')
  end

  # 'core' must be globally unique
  dupe_cores = default_resources.map { |e| e.slice('id', 'core', 'host', 'cpu', 'cpuset') }.group_by { |e| e['core'] }.to_a.select { |e| e[1].length > 1 }
  unless dupe_cores.empty?
    puts "ERROR: some resources have the same 'core' value. it should be globally unique."
    ret = false
    pp dupe_cores if options[:verbose]
  end

  # 'cpu' must be unique to a 'host'
  dupe_cpus = default_resources.map { |e| [e['cpu'], e['host'] ]}.uniq.group_by { |e| e[0] }.to_a.select { |e| e[1].length > 1 }
  unless dupe_cpus.empty?
    puts "ERROR: some hosts have the same 'cpu' value. it should be globally unique."
    ret = false
    pp dupe_cores if options[:verbose]
  end

  # for each host ...
  default_resources.map { |e| e['host'] }.uniq.each do |host|
    host_resources = default_resources.select { |e| e['host'] == host }
    next if options[:clusters] and not options[:clusters].include?(host_resources['cluster'])

    # compute nbcores.
    # cpucore is cores per cpu. to know the number of cpus, we devide memnode per memcpu.
    nbcores = host_resources.map { |e| e['cpucore'] * (e['memnode'] / e['memcpu']) }.uniq
    if nbcores.length > 1
      raise "Invalid: varying nbcores inside cluster!"
    end
    nbcores = nbcores.first

    if host_resources.length != nbcores
      puts "ERROR: invalid number of resources for #{host}. should be nbcores."
      ret = false
    end

    # ids, cpus, cores should follow the physical order (provided by cpuset)
    host_cores = host_resources.map { |e| e['core'] }
    host_cores_min = host_cores.first
    host_cores_max = host_cores.last
    if host_cores_max - host_cores_min + 1 != nbcores
      puts "ERROR: core values for #{host} are not sequential"
      ret = false
    end
    host_cpusets = host_resources.map { |e| e['cpuset'] }
    host_cpusets_min = host_cpusets.first
    host_cpusets_max = host_cpusets.last
    if host_cpusets_min != 0
      puts "ERROR: first cpuset value for #{host} should be 0"
      ret = false
    end
    if host_cpusets_max - host_cpusets_min + 1 != nbcores
      puts "ERROR: cpuset values for #{host} are not sequential"
      ret = false
    end
    if options[:verbose] and (host_cpusets_max - host_cpusets_min + 1 != nbcores or host_cores_max - host_cores_min + 1 != nbcores)
      puts "id   cpu   core   cpuset"
      pp host_resources.map { |e| [e['id'], e['cpu'], e['core'], e['cpuset'] ] }
    end
  end
end

exit ret
