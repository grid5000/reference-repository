require 'simplecov'

SimpleCov.start do
  add_filter '/tests/'
  add_filter '/bundle/'
  add_filter '/spec/'
end
# This outputs the report to your public folder
# You will want to add this to .gitignore
SimpleCov.coverage_dir 'coverage'

require 'rspec'
require 'webmock/rspec'

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../lib')))
require 'refrepo'
require 'refrepo/gen/oar-properties'

STUBDIR = File.expand_path(File.dirname(__FILE__))

WebMock.disable_net_connect!(allow_localhost: true)

def load_stub_file_content(stub_filename)
  if not File.exist?("#{STUBDIR}/stub_oar_properties/#{stub_filename}")
    raise("Cannot find #{stub_filename} in '#{STUBDIR}/stub_oar_properties/'")
  end
  return IO.read("#{STUBDIR}/stub_oar_properties/#{stub_filename}")
end

# This code comes from https://gist.github.com/herrphon/2d2ebbf23c86a10aa955
# and enables to capture all output made on stdout and stderr by a block of code
def capture(&_block)
  begin
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
    result = {}
    result[:stdout] = $stdout.string
    result[:stderr] = $stderr.string
  ensure
    $stdout = STDOUT
    $stderr = STDERR
  end
  result
end


def str_block_to_regexp(str)
  str1 = str.gsub("|", "\\\\|")
  str2 = str1.gsub("+", "\\\\+")
  return Regexp.new str2
end

def prepare_stubs(oar_api, data_hierarchy)
  conf = RefRepo::Utils.get_api_config
  stubbed_addresses = [
    "#{conf["uri"]}",
    "#{conf["uri"]}/oarapi/resources/details.json?limit=999999",
    "#{conf["uri"]}stable/sites/fakesite/internal/oarapi/resources/details.json?limit=999999",
  ]
  stubbed_api_response = load_stub_file_content(oar_api)
  stubbed_addresses.each do |stubbed_address|
    stub_request(:get, stubbed_address).
      with(
        headers: {
          'Accept'=>'*/*',
        }).
        to_return(status: 200, body: stubbed_api_response, headers: {})
  end

  # Overload the 'load_data_hierarchy' to simulate the addition of a fake site in the input files
  expect_any_instance_of(Object).to receive(:load_data_hierarchy).and_return(JSON::parse(load_stub_file_content(data_hierarchy)))
end

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
    'diff'  => { :table => false, :print => false, :update => false, :diff => true, :site => "fakesite", :clusters => ["clustera"] }
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

