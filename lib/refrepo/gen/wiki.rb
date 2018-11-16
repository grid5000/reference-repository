#!/usr/bin/env ruby

require 'refrepo/gen/wiki/wiki_generator'
require 'refrepo/gen/wiki/mw_utils'
require 'refrepo/gen/wiki/generators/cpu_parameters'
require 'refrepo/gen/wiki/generators/disk_reservation'
require 'refrepo/gen/wiki/generators/hardware'
require 'refrepo/gen/wiki/generators/oar_properties'
require 'refrepo/gen/wiki/generators/site_hardware'
require 'refrepo/gen/wiki/generators/site_network'

module RefRepo::Gen::Wiki

  GLOBAL_GENERATORS = {
    'cpu_parameters' => {
      :gen => CPUParametersGenerator,
      :page => "Generated/CPUParameters"
    },
    'disk_reservation' => { 
      :gen => DiskReservationGenerator,
      :page => 'Generated/DiskReservation'
    },
    'hardware' => {
      :gen => G5KHardwareGenerator,
      :page => 'Hardware'
    },
    'oar_properties' => {
      :gen => OarPropertiesGenerator,
      :page => 'OAR_Properties'
    }
  }
  SITE_GENERATORS = {
    'site_hardware' => {
      :gen => SiteHardwareGenerator,
      :page_suffix => ':Hardware'
    },
    'site_network' => {
      :gen => SiteNetworkGenerator,
      :page_suffix => ':GeneratedNetwork'
    }
  }
  GENERATORS = GLOBAL_GENERATORS.merge(SITE_GENERATORS)

  def self.wikigen(options)
    ret = true
    myopts = options.clone
    options[:generators].each do |g|
      myopts[:generators] = [g]
      options[:sites].each do |s|
        myopts[:sites] = [s]
        if GLOBAL_GENERATORS.has_key?(g) and s == 'global'
          ret &= GLOBAL_GENERATORS[g][:gen].new(GLOBAL_GENERATORS[g][:page]).exec(myopts)
        elsif SITE_GENERATORS.has_key?(g) and s != 'global'
          ret &= SITE_GENERATORS[g][:gen].new(s.capitalize + SITE_GENERATORS[g][:page_suffix], s).exec(myopts)
        else
          puts "Nothing to do: #{g}/#{s}"
        end
      end
    end
    return ret
  end
end
