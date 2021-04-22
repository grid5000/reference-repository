$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
require 'spec_helper'

describe 'OarProperties' do

  context 'interracting with an empty OAR server' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_empty', :data => 'data', :case => 'empty' })
    end
  end

  context 'OAR server with data' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_configured', :data => 'data', :case => 'with-data' })
    end
  end

  context 'interracting with an empty OAR server (round-robin cpusets)' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_empty', :data => 'data_round_robin_cpusets', :case => 'empty_round_robin' })
    end
  end

  context 'interracting with an empty OAR server (contiguous_including_threads cpusets)' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_empty', :data => 'data_contiguous-including-threads_cpusets', :case => 'empty_contiguous-including-threads_cpusets' })
    end
  end

  context 'interracting with an empty OAR server (contiguous_grouped_by_threads cpusets)' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_empty', :data => 'data_contiguous-grouped-by-threads_cpusets', :case => 'empty_contiguous-grouped-by-threads_cpusets' })
    end
  end


  context 'interracting with an empty OAR server (cluster with disk)' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_empty', :data => 'data_with_disk', :case => 'empty_with_disk' })
    end
  end

  context 'OAR server with data (cluster with disk)' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_with_disk', :data => 'data_with_disk', :case => 'configured_with_disk' })
    end
  end

  context 'interracting with an empty OAR server (without gpu)' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_empty', :data => 'data_without_gpu', :case => 'empty_without_gpu' })
    end
  end

  context 'interracting with a configured OAR server (without gpu)' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_without_gpu', :data => 'data_without_gpu', :case => 'configured_without_gpu' })
    end
  end

  context 'interracting with a configured OAR server (quirk cluster)' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_quirk_cluster', :data => 'data_without_gpu', :case => 'configured_without_gpu_quirk_cluster' })
    end
  end

  context 'interracting with a configured OAR server (misconfigured cores)' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_misconfigured_cores', :data => 'data_without_gpu', :case => 'configured_misconfigured_cores' })
    end
  end

  context 'interracting with a configured OAR server (misconfigured gpu)' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_misconfigured_gpu', :data => 'data_without_gpu', :case => 'configured_misconfigured_gpu' })
    end
  end

  context 'interracting with a configured OAR server (msising network interfaces)' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_configured', :data => 'data_missing_main_network_property', :case => 'configured_missing_network_interfaces' })
    end
  end

  context 'interracting with a configured OAR server (wrong variable type for gpu)' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_wrong_vartype', :data => 'data', :case => 'wrong_variable_type' })
    end
  end

  context 'interracting with a configured OAR server (different_values for wattmeters)' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_configured', :data => 'data_wattmeters_variations', :case => 'different_value_wattmeters' })
    end
  end

  context 'interracting with a configured OAR server (no wattmeters)' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_configured', :data => 'data_wattmeters_nil', :case => 'wattmeters_nil' })
    end
  end

  context 'interracting with a configured OAR server (with missing property)' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_missing_property', :data => 'data', :case => 'missing_property' })
    end
  end

  context 'interracting with a configured OAR server (non reservable GPUs)' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_configured', :data => 'data_with_non_reservable_gpus', :case => 'non_reservable_gpus' })
    end
  end

  context 'interracting with a configured same CPUs, COREs, GPUS, allocated to different servers' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_duplicated_cpus_cores_gpus', :data => 'data', :case => 'duplicated_cpus_cores_gpus' })
    end
  end

  context 'interracting with a configured same CPUs, COREs, GPUS, allocated to different servers' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_with_too_many_oar_resources', :data => 'data', :case => 'with_too_many_oar_resources' })
    end
  end

  context 'interracting with a configured same CPUs, COREs, GPUS, allocated to different servers' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_with_too_few_oar_resources', :data => 'data', :case => 'with_too_few_oar_resources' })
    end
  end

  context 'interracting with a cluster with misconfigured resources, errors in its OAR properties and some misconfigured disks' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_with_disk_misconfigured_resources_properties_and_disks', :data => 'data_with_disk', :case => 'with_disk_misconfigured_resources_properties_and_disks' })
    end
  end

  context 'OAR server with data' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_configured', :data => 'data_bad_best_effort_property', :case => 'bad_best_effort_property' })
    end
  end

  context 'OAR server with data but chassis is unset' do
    it 'should work correctly' do
      check_oar_properties({ :oar => 'oar_but_chassis_unset', :data => 'data', :case => 'chassis_unset' })
    end
  end
end
