$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
require 'spec_helper'

def gen_stub(file, site, cluster, node_count = 9999)
  data = load_data_hierarchy
  data['sites'].delete_if { |k, v| site != k }
  data['sites'].each_pair do |site_uid, s|
    s['clusters'].delete_if { |k, v| cluster != k }
  end
  data.delete('network_equipments')
  data['sites']['fakesite'] = data['sites'][site]
  data['sites'].delete(site)
  c = data['sites']['fakesite']['clusters']
  c['clustera'] = c[cluster]
  c.delete(cluster)
  c['clustera']['uid'] = 'clustera'
  nodes = c['clustera']['nodes']
  nodes.keys.each do |k|
    c, n = k.split('-')
    nodes["clustera-#{n}"] = nodes[k] if n.to_i <= node_count
    nodes.delete(k)
  end

  File::open("spec/input/#{file}.json", "w") do |fd|
    fd.puts JSON::pretty_generate(data)
  end
end

def check_oar_properties(o)
  conf = RefRepo::Utils.get_api_config
  specdir = File.expand_path(File.dirname(__FILE__))
  stubbed_addresses = [
    "#{conf["uri"]}",
    "#{conf["uri"]}/oarapi/resources/details.json?limit=999999",
    "#{conf["uri"]}stable/sites/fakesite/internal/oarapi/resources/details.json?limit=999999",
  ]
  stubbed_api_response = IO.read("#{specdir}/input/#{o[:oar]}.json")
  stubbed_addresses.each do |stubbed_address|
    stub_request(:get, stubbed_address).
      with(
        headers: {
          'Accept'=>'*/*',
        }).
        to_return(status: 200, body: stubbed_api_response, headers: {})
  end

  # Overload the 'load_data_hierarchy' to simulate the addition of a fake site in the input files
  expect_any_instance_of(Object).to receive(:load_data_hierarchy).exactly(3).and_return(JSON::parse(IO.read("#{specdir}/input/#{o[:data]}.json")))

  uri = URI(conf["uri"])
  response = Net::HTTP.get(uri)
  expect(response).to be_an_instance_of(String)
  {
    'table' => { :table => true, :print => false, :update => false, :diff => false, :site => "fakesite", :clusters => ["clustera"] },
    'print' => { :table => false, :print => true, :update => false, :diff => false, :site => "fakesite", :clusters => ["clustera"] },
    'diff'  => { :table => false, :print => false, :update => false, :diff => true, :verbose => 2, :site => "fakesite", :clusters => ["clustera"] }
  }.each_pair do |type, options|
    output = capture do
      generate_oar_properties(options)
    end
    # stdout
    ofile = "#{specdir}/output/#{o[:case]}_#{type}_stdout.txt"
    if not File::exist?(ofile)
      puts "Output file #{ofile} did not exist, created."
      File::open(ofile, "w") { |fd| fd.print output[:stdout] }
      ofile_data = output[:stdout]
    else
      ofile_data = IO::read(ofile)
    end
    expect(output[:stdout]).to eq(ofile_data)
    # stderr
    ofile = "#{specdir}/output/#{o[:case]}_#{type}_stderr.txt"
    if not File::exist?(ofile)
      puts "Output file #{ofile} did not exist, created."
      File::open(ofile, "w") { |fd| fd.print output[:stderr] }
      ofile_data = output[:stderr]
    else
      ofile_data = IO::read(ofile)
    end
    expect(output[:stderr]).to eq(ofile_data)

  end
end

=begin
gen_stub('data_graffiti', 'nancy', 'graffiti')
gen_stub('data_grimoire', 'nancy', 'grimoire')
gen_stub('data_graphite', 'nancy', 'graphite')
gen_stub('data_yeti', 'grenoble', 'yeti')
gen_stub('data_grue', 'nancy', 'grue')
=end

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

  it 'works on a cluster with GPUs and cores_affinity, on an empty OAR server' do
    check_oar_properties({ :oar => 'oar_empty', :data => 'data_grue', :case => 'grue_empty' })
  end

  it 'works on a cluster with GPUs and cores_affinity, on configured OAR server without GPUs' do
    check_oar_properties({ :oar => 'oar_grue-without-gpus', :data => 'data_grue', :case => 'grue_nogpus' })
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
