require 'refrepo/gen/wiki/wiki_generator'
require 'refrepo/gen/wiki/mw_utils'
require 'refrepo/gen/wiki/generators/cpu_parameters'
require 'refrepo/gen/wiki/generators/disk_reservation'
require 'refrepo/gen/wiki/generators/hardware'
require 'refrepo/gen/wiki/generators/oar_properties'
require 'refrepo/gen/wiki/generators/site_hardware'
require 'refrepo/gen/wiki/generators/site_network'
require 'refrepo/gen/wiki/generators/status'
require 'refrepo/gen/wiki/generators/group_storage'
require 'refrepo/gen/wiki/generators/environments'
require 'refrepo/gen/wiki/generators/licenses'
require 'refrepo/gen/wiki/generators/kwollect_metrics'
require 'refrepo/gen/wiki/generators/oarsub_simplifier_aliases'
require 'refrepo/gen/wiki/generators/modules_list'

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
    'status' => {
      :gen => StatusGenerator,
      :page => 'Status'
    },
    'oar_properties' => {
      :gen => OarPropertiesGenerator,
      :page => 'OAR_Properties'
    },
    'group_storage' => {
      :gen => GroupStorageGenerator,
      :page => 'Generated/GroupStorage'
    },
    'environments' => {
      :gen => EnvironmentsGenerator,
      :page => 'Generated/Environments'
    },
    'licenses' => {
      :gen => LicensesGenerator,
      :page => 'Generated/Licenses'
    },
    'kwollect_metrics' => {
      :gen => KwollectMetricsGenerator,
      :page => 'Generated/KwollectMetrics'
    },
    'oarsub_simplifier_aliases' => {
      :gen => OarsubSimplifierAliasesGenerator,
      :page => 'Generated/OarsubSimplifierAliases'
    },
    'modules_list' => {
      :gen => ModulesList,
      :page => 'Generated/ModulesList'
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
