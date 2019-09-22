$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
require 'spec_helper'
require 'rspec'
require 'webmock/rspec'

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../lib')))
require 'refrepo'
require 'refrepo/gen/oar-properties'

STUBDIR = File.expand_path(File.dirname(__FILE__))

WebMock.disable_net_connect!(allow_localhost: true)

conf = RefRepo::Utils.get_api_config

def load_stub_file_content(stub_filename)
  if not File.exist?("#{STUBDIR}/stub_oar_properties/#{stub_filename}")
    raise("Cannot find #{stub_filename} in '#{STUBDIR}/stub_oar_properties/'")
  end
  file = File.open("#{STUBDIR}/stub_oar_properties/#{stub_filename}", "r")
  lines = IO.read(file)
  file.close()
  return lines
end

# This code comes from https://gist.github.com/herrphon/2d2ebbf23c86a10aa955
# and enables to capture all output made on stdout and stderr by a block of code
def capture(&block)
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

stubbed_addresses = [
    "#{conf["uri"]}",
    "#{conf["uri"]}/oarapi/resources/details.json?limit=999999",
]


def str_block_to_regexp(str)
  str1 = str.gsub("|", "\\\\|")
  str2 = str1.gsub("+", "\\\\+")
  return Regexp.new str2
end

describe 'Oar properties generator' do

  context 'interracting with an empty OAR server' do
    before do
      stubbed_api_response = load_stub_file_content("dump_oar_api_empty_server.json")
      stubbed_addresses.each do |stubbed_address|
        stub_request(:get, stubbed_address).
            with(
                headers: {
                    'Accept'=>'*/*',
                }).
            to_return(status: 200, body: stubbed_api_response, headers: {})
      end

      # Overload the 'load_data_hierarchy' to simulate the addition of a fake site in the input files
      def load_data_hierarchy
        json_str = load_stub_file_content("load_data_hierarchy_stubbed_data.json")
        return JSON.parse(json_str)
      end
    end

    it 'should generate correctly a table of nodes' do

      uri = URI(conf["uri"])

      response = Net::HTTP.get(uri)

      expect(response).to be_an_instance_of(String)

      options = {
          :table => true,
          :print => false,
          :update => false,
          :diff => false,
          :site => "fakesite",
          :clusters => ["clustera"]
      }

      expected_header = <<-TXT
+---------- + -------------------- + ----- + ----- + -------- + ---- + -------------------- + ------------------------------ + ------------------------------+
|   cluster | host                 | cpu   | core  | cpuset   | gpu  | gpudevice            | cpumodel                       | gpumodel                      |
+---------- + -------------------- + ----- + ----- + -------- + ---- + -------------------- + ------------------------------ + ------------------------------+
TXT

      expected_clustera1_desc = <<-TXT
|  clustera | clustera-1           | 1     | 1     | 0        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-1           | 1     | 2     | 1        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-1           | 1     | 3     | 2        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-1           | 1     | 4     | 3        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-1           | 1     | 5     | 4        | 2    | 1                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-1           | 1     | 6     | 5        | 2    | 1                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
TXT

      expected_clustera2_desc = <<-TXT
|  clustera | clustera-2           | 4     | 26    | 9        | 7    | 2                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-2           | 4     | 27    | 10       | 7    | 2                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-2           | 4     | 28    | 11       | 7    | 2                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-2           | 4     | 29    | 12       | 8    | 3                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-2           | 4     | 30    | 13       | 8    | 3                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-2           | 4     | 31    | 14       | 8    | 3                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-2           | 4     | 32    | 15       | 8    | 3                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_header)
      expect(generator_output[:stdout]).to include(expected_clustera1_desc)
      expect(generator_output[:stdout]).to include(expected_clustera2_desc)
    end

    it 'should generate correctly all the commands to update OAR' do

      uri = URI(conf["uri"])

      response = Net::HTTP.get(uri)

      expect(response).to be_an_instance_of(String)

      options = {
          :table => false,
          :print => true,
          :update => false,
          :diff => false,
          :site => "fakesite",
          :clusters => ["clustera"]
      }

      expected_header = <<-TXT
#############################################
# Create OAR properties that were created by 'oar_resources_add'
#############################################
property_exist 'host' || oarproperty -a host --varchar
property_exist 'cpu' || oarproperty -a cpu
property_exist 'core' || oarproperty -a core
property_exist 'gpudevice' || oarproperty -a gpudevice
property_exist 'gpu' || oarproperty -a gpu
property_exist 'gpu_model' || oarproperty -a gpu_model --varchar
TXT

      expected_clustera1_cmds = <<-TXT
###################################
# clustera-1.fakesite.grid5000.fr
###################################
oarnodesetting -a -h 'clustera-1.fakesite.grid5000.fr' -p host='clustera-1.fakesite.grid5000.fr' -p cpu=1 -p core=1 -p cpuset=0 -p gpu=1 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting -a -h 'clustera-1.fakesite.grid5000.fr' -p host='clustera-1.fakesite.grid5000.fr' -p cpu=1 -p core=2 -p cpuset=1 -p gpu=1 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting -a -h 'clustera-1.fakesite.grid5000.fr' -p host='clustera-1.fakesite.grid5000.fr' -p cpu=1 -p core=3 -p cpuset=2 -p gpu=1 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
TXT

      expected_clustera2_cmds = <<-TXT
oarnodesetting -a -h 'clustera-2.fakesite.grid5000.fr' -p host='clustera-2.fakesite.grid5000.fr' -p cpu=4 -p core=29 -p cpuset=12 -p gpu=8 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=3 # This GPU is mapped on /dev/nvidia3
oarnodesetting -a -h 'clustera-2.fakesite.grid5000.fr' -p host='clustera-2.fakesite.grid5000.fr' -p cpu=4 -p core=30 -p cpuset=13 -p gpu=8 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=3 # This GPU is mapped on /dev/nvidia3
oarnodesetting -a -h 'clustera-2.fakesite.grid5000.fr' -p host='clustera-2.fakesite.grid5000.fr' -p cpu=4 -p core=31 -p cpuset=14 -p gpu=8 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=3 # This GPU is mapped on /dev/nvidia3
oarnodesetting -a -h 'clustera-2.fakesite.grid5000.fr' -p host='clustera-2.fakesite.grid5000.fr' -p cpu=4 -p core=32 -p cpuset=15 -p gpu=8 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=3 # This GPU is mapped on /dev/nvidia3
TXT
      expected_clustera3_cmds = <<-TXT
oarnodesetting --sql "host='clustera-2.fakesite.grid5000.fr' and type='default'" -p ip='172.16.64.2' -p cluster='clustera' -p nodemodel='Dell PowerEdge T640' -p switch='gw-fakesite' -p virtual='ivt' -p cpuarch='x86_64' -p cpucore=8 -p cputype='Intel Xeon Silver 4110' -p cpufreq='2.1' -p disktype='SATA' -p eth_count=1 -p eth_rate=10 -p ib_count=0 -p ib_rate=0 -p ib='NO' -p opa_count=0 -p opa_rate=0 -p opa='NO' -p myri_count=0 -p myri_rate=0 -p myri='NO' -p memcore=8192 -p memcpu=65536 -p memnode=131072 -p gpu_count=4 -p mic='NO' -p wattmeter='MULTIPLE' -p cluster_priority=201906 -p max_walltime=86400 -p production='YES' -p maintenance='NO' -p disk_reservation_count=0
TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_header)
      expect(generator_output[:stdout]).to include(expected_clustera1_cmds)
      expect(generator_output[:stdout]).to include(expected_clustera2_cmds)
      expect(generator_output[:stdout]).to include(expected_clustera3_cmds)
    end

    it 'should generate correctly a diff with the OAR server' do

      uri = URI(conf["uri"])

      response = Net::HTTP.get(uri)

      expect(response).to be_an_instance_of(String)

      options = {
          :table => false,
          :print => false,
          :update => false,
          :diff => true,
          :site => "fakesite",
          :clusters => ["clustera"],
          :verbose => 2
      }

      expected_clustera1_diff = <<-TXT
  clustera-1: new node !
    ["+", "cluster", "clustera"]
    ["+", "cluster_priority", 201906]
    ["+", "cpuarch", "x86_64"]
    ["+", "cpucore", 8]
    ["+", "cpufreq", "2.1"]
    ["+", "cputype", "Intel Xeon Silver 4110"]
    ["+", "disk_reservation_count", 0]
    ["+", "disktype", "SATA"]
    ["+", "eth_count", 1]
    ["+", "eth_rate", 10]
    ["+", "gpu_count", 4]
    ["+", "ib", "NO"]
    ["+", "ib_count", 0]
    ["+", "ib_rate", 0]
    ["+", "ip", "172.16.64.1"]
    ["+", "maintenance", "NO"]
    ["+", "max_walltime", 86400]
    ["+", "memcore", 8192]
    ["+", "memcpu", 65536]
    ["+", "memnode", 131072]
    ["+", "mic", "NO"]
    ["+", "myri", "NO"]
    ["+", "myri_count", 0]
    ["+", "myri_rate", 0]
    ["+", "nodemodel", "Dell PowerEdge T640"]
    ["+", "opa", "NO"]
    ["+", "opa_count", 0]
    ["+", "opa_rate", 0]
    ["+", "production", "YES"]
    ["+", "switch", "gw-fakesite"]
    ["+", "virtual", "ivt"]
    ["+", "wattmeter", "MULTIPLE"]
TXT

      expected_clustera2_diff = <<-TXT
  clustera-2: new node !
    ["+", "cluster", "clustera"]
    ["+", "cluster_priority", 201906]
    ["+", "cpuarch", "x86_64"]
    ["+", "cpucore", 8]
    ["+", "cpufreq", "2.1"]
    ["+", "cputype", "Intel Xeon Silver 4110"]
    ["+", "disk_reservation_count", 0]
    ["+", "disktype", "SATA"]
    ["+", "eth_count", 1]
    ["+", "eth_rate", 10]
    ["+", "gpu_count", 4]
    ["+", "ib", "NO"]
    ["+", "ib_count", 0]
    ["+", "ib_rate", 0]
    ["+", "ip", "172.16.64.2"]
    ["+", "maintenance", "NO"]
    ["+", "max_walltime", 86400]
    ["+", "memcore", 8192]
    ["+", "memcpu", 65536]
    ["+", "memnode", 131072]
    ["+", "mic", "NO"]
    ["+", "myri", "NO"]
    ["+", "myri_count", 0]
    ["+", "myri_rate", 0]
    ["+", "nodemodel", "Dell PowerEdge T640"]
    ["+", "opa", "NO"]
    ["+", "opa_count", 0]
    ["+", "opa_rate", 0]
    ["+", "production", "YES"]
    ["+", "switch", "gw-fakesite"]
    ["+", "virtual", "ivt"]
    ["+", "wattmeter", "MULTIPLE"]
TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_clustera1_diff)
      expect(generator_output[:stdout]).to include(expected_clustera2_diff)
    end
  end



  context 'OAR server with data' do
    before do
      stubbed_api_response = load_stub_file_content("dump_oar_api_configured_server.json")
      stubbed_addresses.each do |stubbed_address|
        stub_request(:get, stubbed_address).
            with(
                headers: {
                    'Accept'=>'*/*',
                }).
            to_return(status: 200, body: stubbed_api_response, headers: {})
      end

      # Overload the 'load_data_hierarchy' to simulate the addition of a fake site in the input files
      def load_data_hierarchy
        json_str = load_stub_file_content("load_data_hierarchy_stubbed_data.json")
        return JSON.parse(json_str)
      end
    end

    it 'should generate correctly a table of nodes' do

      uri = URI(conf["uri"])

      response = Net::HTTP.get(uri)

      expect(response).to be_an_instance_of(String)

      options = {
          :table => true,
          :print => false,
          :update => false,
          :diff => false,
          :site => "fakesite",
          :clusters => ["clustera"]
      }

      expected_header = <<-TXT
+---------- + -------------------- + ----- + ----- + -------- + ---- + -------------------- + ------------------------------ + ------------------------------+
|   cluster | host                 | cpu   | core  | cpuset   | gpu  | gpudevice            | cpumodel                       | gpumodel                      |
+---------- + -------------------- + ----- + ----- + -------- + ---- + -------------------- + ------------------------------ + ------------------------------+
      TXT

      expected_clustera1_desc = <<-TXT
|  clustera | clustera-1           | 1     | 1     | 0        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-1           | 1     | 2     | 1        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-1           | 1     | 3     | 2        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-1           | 1     | 4     | 3        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-1           | 1     | 5     | 4        | 2    | 1                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-1           | 1     | 6     | 5        | 2    | 1                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
      TXT

      expected_clustera2_desc = <<-TXT
|  clustera | clustera-2           | 4     | 26    | 9        | 7    | 2                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-2           | 4     | 27    | 10       | 7    | 2                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-2           | 4     | 28    | 11       | 7    | 2                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-2           | 4     | 29    | 12       | 8    | 3                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-2           | 4     | 30    | 13       | 8    | 3                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-2           | 4     | 31    | 14       | 8    | 3                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-2           | 4     | 32    | 15       | 8    | 3                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_header)
      expect(generator_output[:stdout]).to include(expected_clustera1_desc)
      expect(generator_output[:stdout]).to include(expected_clustera2_desc)
    end

    it 'should generate correctly all the commands to update OAR' do

      uri = URI(conf["uri"])

      response = Net::HTTP.get(uri)

      expect(response).to be_an_instance_of(String)

      options = {
          :table => false,
          :print => true,
          :update => false,
          :diff => false,
          :site => "fakesite",
          :clusters => ["clustera"]
      }

      expected_header = <<-TXT
#############################################
# Create OAR properties that were created by 'oar_resources_add'
#############################################
property_exist 'host' || oarproperty -a host --varchar
property_exist 'cpu' || oarproperty -a cpu
property_exist 'core' || oarproperty -a core
property_exist 'gpudevice' || oarproperty -a gpudevice
property_exist 'gpu' || oarproperty -a gpu
property_exist 'gpu_model' || oarproperty -a gpu_model --varchar
      TXT

      expected_clustera1_cmds = <<-TXT
###################################
# clustera-1.fakesite.grid5000.fr
###################################
oarnodesetting --sql "host='clustera-1.fakesite.grid5000.fr' AND resource_id='1' AND type='default'" -p cpu=1 -p core=1 -p cpuset=0 -p gpu=1 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting --sql "host='clustera-1.fakesite.grid5000.fr' AND resource_id='2' AND type='default'" -p cpu=1 -p core=2 -p cpuset=1 -p gpu=1 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting --sql "host='clustera-1.fakesite.grid5000.fr' AND resource_id='3' AND type='default'" -p cpu=1 -p core=3 -p cpuset=2 -p gpu=1 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting --sql "host='clustera-1.fakesite.grid5000.fr' AND resource_id='4' AND type='default'" -p cpu=1 -p core=4 -p cpuset=3 -p gpu=1 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
      TXT

      expected_clustera2_cmds = <<-TXT
###################################
# clustera-2.fakesite.grid5000.fr
###################################
oarnodesetting --sql "host='clustera-2.fakesite.grid5000.fr' AND resource_id='17' AND type='default'" -p cpu=3 -p core=17 -p cpuset=0 -p gpu=5 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting --sql "host='clustera-2.fakesite.grid5000.fr' AND resource_id='18' AND type='default'" -p cpu=3 -p core=18 -p cpuset=1 -p gpu=5 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting --sql "host='clustera-2.fakesite.grid5000.fr' AND resource_id='19' AND type='default'" -p cpu=3 -p core=19 -p cpuset=2 -p gpu=5 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting --sql "host='clustera-2.fakesite.grid5000.fr' AND resource_id='20' AND type='default'" -p cpu=3 -p core=20 -p cpuset=3 -p gpu=5 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting --sql "host='clustera-2.fakesite.grid5000.fr' AND resource_id='21' AND type='default'" -p cpu=3 -p core=21 -p cpuset=4 -p gpu=6 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=1 # This GPU is mapped on /dev/nvidia1
      TXT

      expected_clustera3_cmds = <<-TXT
oarnodesetting --sql "host='clustera-2.fakesite.grid5000.fr' and type='default'" -p ip='172.16.64.2' -p cluster='clustera' -p nodemodel='Dell PowerEdge T640' -p switch='gw-fakesite' -p virtual='ivt' -p cpuarch='x86_64' -p cpucore=8 -p cputype='Intel Xeon Silver 4110' -p cpufreq='2.1' -p disktype='SATA' -p eth_count=1 -p eth_rate=10 -p ib_count=0 -p ib_rate=0 -p ib='NO' -p opa_count=0 -p opa_rate=0 -p opa='NO' -p myri_count=0 -p myri_rate=0 -p myri='NO' -p memcore=8192 -p memcpu=65536 -p memnode=131072 -p gpu_count=4 -p mic='NO' -p wattmeter='MULTIPLE' -p cluster_priority=201906 -p max_walltime=86400 -p production='YES' -p maintenance='NO' -p disk_reservation_count=0
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_header)
      expect(generator_output[:stdout]).to include(expected_clustera1_cmds)
      expect(generator_output[:stdout]).to include(expected_clustera2_cmds)
      expect(generator_output[:stdout]).to include(expected_clustera3_cmds)
    end

    it 'should generate correctly a diff with the OAR server' do

      uri = URI(conf["uri"])

      response = Net::HTTP.get(uri)

      expect(response).to be_an_instance_of(String)

      options = {
          :table => false,
          :print => false,
          :update => false,
          :diff => true,
          :site => "fakesite",
          :clusters => ["clustera"],
          :verbose => 2
      }

      expected_clustera1_diff = <<-TXT
  clustera-1: OK
TXT

      expected_clustera2_diff = <<-TXT
  clustera-2: OK
TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_clustera1_diff)
      expect(generator_output[:stdout]).to include(expected_clustera2_diff)
    end
  end
end