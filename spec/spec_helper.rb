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
