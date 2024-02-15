$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
require 'spec_helper'

describe 'OarProperties2' do
  it 'works on a cluster with GPUs, on an empty OAR server' do
    check_oar_properties({ :oar => 'oar_empty', :data => 'data_graffiti', :case => 'graffiti_empty' })
  end

  it 'works on a cluster with reservable disks, on an empty OAR server' do
    check_oar_properties({ :oar => 'oar_empty', :data => 'data_grimoire', :case => 'grimoire_empty' })
  end

  it 'works on a cluster with MICs, on an empty OAR server' do
    check_oar_properties({ :oar => 'oar_empty', :data => 'data_graphite', :case => 'graphite_empty' })
  end

  it 'works on a cluster with OPA, on an empty OAR server' do
    check_oar_properties({ :oar => 'oar_empty', :data => 'data_yeti', :case => 'yeti_empty' })
  end

  it 'works on a cluster with multiple nodes per chassis, on an empty OAR server' do
    check_oar_properties({ :oar => 'oar_empty', :data => 'data_dahu', :case => 'dahu_empty' })
  end

  it 'works on a cluster with GPUs and cores_affinity, on an empty OAR server' do
    check_oar_properties({ :oar => 'oar_empty', :data => 'data_grue', :case => 'grue_empty' })
  end

  it 'works on a cluster with GPUs and cores_affinity, on configured OAR server without GPUs' do
    check_oar_properties({ :oar => 'oar_grue-without-gpus', :data => 'data_grue', :case => 'grue_nogpus' })
  end

  it 'works on a cluster with more CPUs than GPUs (2 CPU, 1 GPU) such as abacus22' do
    check_oar_properties({ :oar => 'oar_empty', :data => 'data_abacus22_2cpu1gpu', :case => 'abacus22_2cpu1gpu' })
  end


  it 'generates an identical output for graffiti when all GPUs are there' do
    check_oar_properties({ :oar => 'oar_graffiti-with-all-gpus', :data => 'data_graffiti2', :case => 'graffiti-all-gpus' })
  end

  it 'generates an output for graffiti when a GPU has been removed, but OAR not updated' do
    check_oar_properties({ :oar => 'oar_graffiti-with-all-gpus', :data => 'data_graffiti2-missing-gpu', :case => 'graffiti-gpu-removed' })
  end

  it 'generates an output for graffiti when a GPU has been removed, and OAR updated' do
    check_oar_properties({ :oar => 'oar_graffiti-with-missing-gpus', :data => 'data_graffiti2-missing-gpu', :case => 'graffiti-gpu-removed-OAR-updated' })
  end

  it 'generates an output for graffiti when a GPU has been removed then re-added, OAR not yet re-updated' do
    check_oar_properties({ :oar => 'oar_graffiti-with-missing-gpus', :data => 'data_graffiti2', :case => 'graffiti-gpu-removed-OAR-updated-gpu-re-added' })
  end

  it 'generates an output for graffiti when a GPU has been removed then re-added, OAR updated' do
    check_oar_properties({ :oar => 'oar_graffiti-with-all-gpus', :data => 'data_graffiti2', :case => 'graffiti-gpu-removed-OAR-updated-gpu-re-added-OAR-updated' })
  end


end
