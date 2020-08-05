$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
require 'spec_helper'

conf = RefRepo::Utils.get_api_config

describe 'OarProperties' do

  context 'testing arguments' do
    before do
      prepare_stubs("dump_oar_api_empty_server.json", "load_data_hierarchy_stubbed_data.json")
    end

    it 'should should accept case where only the site is specified' do

      uri = URI(conf["uri"])

      response = Net::HTTP.get(uri)

      expect(response).to be_an_instance_of(String)

      options = {
          :table => true,
          :print => false,
          :update => false,
          :diff => false,
          :site => "fakesite",
      }

      expected_header = <<-TXT
+---------- + -------------------- + ----- + ----- + -------- + ---- + -------------------- + ------------------------------ + ------------------------------+
|   cluster | host                 | cpu   | core  | cpuset   | gpu  | gpudevice            | cpumodel                       | gpumodel                      |
+---------- + -------------------- + ----- + ----- + -------- + ---- + -------------------- + ------------------------------ + ------------------------------+
TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_header)
    end

    it 'should should accept case where only the site is specified' do

      uri = URI(conf["uri"])

      response = Net::HTTP.get(uri)

      expect(response).to be_an_instance_of(String)

      options = {
          :table => true,
          :print => false,
          :update => false,
          :diff => false,
          :site => "fakesite2",
      }

      expect { generate_oar_properties(options) }.to raise_error("The provided site does not exist : I can't detect clusters")
    end
  end

  context 'interracting with an empty OAR server' do
    before do
      prepare_stubs("dump_oar_api_empty_server.json", "load_data_hierarchy_stubbed_data.json")
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
oarnodesetting --sql "host='clustera-2.fakesite.grid5000.fr' and type='default'" -p ip='172.16.64.2' -p cluster='clustera' -p nodemodel='Dell PowerEdge T640' -p switch='gw-fakesite' -p besteffort='YES' -p deploy='YES' -p virtual='ivt' -p cpuarch='x86_64' -p cpucore=8 -p cputype='Intel Xeon Silver 4110' -p cpufreq='2.1' -p disktype='SATA' -p chassis='Dell Inc. PowerEdge T640 9L1CBX2' -p eth_count=1 -p eth_rate=10 -p ib_count=0 -p ib_rate=0 -p ib='NO' -p opa_count=0 -p opa_rate=0 -p myri_count=0 -p myri_rate=0 -p myri='NO' -p memcore=8192 -p memcpu=65536 -p memnode=131072 -p gpu_count=4 -p exotic='NO' -p mic='NO' -p wattmeter='MULTIPLE' -p cluster_priority=201906 -p max_walltime=86400 -p production='YES' -p maintenance='NO' -p disk_reservation_count=0
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
    ["+", "besteffort", "YES"]
    ["+", "chassis", "Dell Inc. PowerEdge T640 FL1CBX2"]
    ["+", "cluster", "clustera"]
    ["+", "cluster_priority", 201906]
    ["+", "cpuarch", "x86_64"]
    ["+", "cpucore", 8]
    ["+", "cpufreq", "2.1"]
    ["+", "cputype", "Intel Xeon Silver 4110"]
    ["+", "deploy", "YES"]
    ["+", "disk_reservation_count", 0]
    ["+", "disktype", "SATA"]
    ["+", "eth_count", 1]
    ["+", "eth_rate", 10]
    ["+", "exotic", "NO"]
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
    ["+", "opa_count", 0]
    ["+", "opa_rate", 0]
    ["+", "production", "YES"]
    ["+", "switch", "gw-fakesite"]
    ["+", "virtual", "ivt"]
    ["+", "wattmeter", "MULTIPLE"]
TXT

      expected_clustera2_diff = <<-TXT
  clustera-2: new node !
    ["+", "besteffort", "YES"]
    ["+", "chassis", "Dell Inc. PowerEdge T640 9L1CBX2"]
    ["+", "cluster", "clustera"]
    ["+", "cluster_priority", 201906]
    ["+", "cpuarch", "x86_64"]
    ["+", "cpucore", 8]
    ["+", "cpufreq", "2.1"]
    ["+", "cputype", "Intel Xeon Silver 4110"]
    ["+", "deploy", "YES"]
    ["+", "disk_reservation_count", 0]
    ["+", "disktype", "SATA"]
    ["+", "eth_count", 1]
    ["+", "eth_rate", 10]
    ["+", "exotic", "NO"]
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
      prepare_stubs("dump_oar_api_configured_server.json", "load_data_hierarchy_stubbed_data.json")
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
oarnodesetting --sql "host='clustera-2.fakesite.grid5000.fr' and type='default'" -p ip='172.16.64.2' -p cluster='clustera' -p nodemodel='Dell PowerEdge T640' -p switch='gw-fakesite' -p besteffort='YES' -p deploy='YES' -p virtual='ivt' -p cpuarch='x86_64' -p cpucore=8 -p cputype='Intel Xeon Silver 4110' -p cpufreq='2.1' -p disktype='SATA' -p chassis='Dell Inc. PowerEdge T640 9L1CBX2' -p eth_count=1 -p eth_rate=10 -p ib_count=0 -p ib_rate=0 -p ib='NO' -p opa_count=0 -p opa_rate=0 -p myri_count=0 -p myri_rate=0 -p myri='NO' -p memcore=8192 -p memcpu=65536 -p memnode=131072 -p gpu_count=4 -p exotic='NO' -p mic='NO' -p wattmeter='MULTIPLE' -p cluster_priority=201906 -p max_walltime=86400 -p production='YES' -p maintenance='NO' -p disk_reservation_count=0
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

  context 'OAR server with data' do
    before do
      prepare_stubs("dump_oar_api_configured_server.json", "load_data_hierarchy_stubbed_data.json")
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

  end

  context 'interracting with an empty OAR server (round-robin cpusets)' do
    before do
      prepare_stubs("dump_oar_api_empty_server.json", "load_data_hierarchy_stubbed_data_round_robin_cpusets.json")
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
|  clustera | clustera-1           | 1     | 2     | 2        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-1           | 1     | 3     | 4        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-1           | 1     | 4     | 6        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-1           | 1     | 5     | 8        | 2    | 1                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-1           | 1     | 6     | 10       | 2    | 1                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
      TXT

      expected_clustera2_desc = <<-TXT
|  clustera | clustera-2           | 4     | 26    | 3        | 7    | 2                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-2           | 4     | 27    | 5        | 7    | 2                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-2           | 4     | 28    | 7        | 7    | 2                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-2           | 4     | 29    | 9        | 8    | 3                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-2           | 4     | 30    | 11       | 8    | 3                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clustera | clustera-2           | 4     | 31    | 13       | 8    | 3                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
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
oarnodesetting -a -h 'clustera-1.fakesite.grid5000.fr' -p host='clustera-1.fakesite.grid5000.fr' -p cpu=1 -p core=2 -p cpuset=2 -p gpu=1 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting -a -h 'clustera-1.fakesite.grid5000.fr' -p host='clustera-1.fakesite.grid5000.fr' -p cpu=1 -p core=3 -p cpuset=4 -p gpu=1 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
      TXT

      expected_clustera2_cmds = <<-TXT
oarnodesetting -a -h 'clustera-2.fakesite.grid5000.fr' -p host='clustera-2.fakesite.grid5000.fr' -p cpu=4 -p core=29 -p cpuset=9 -p gpu=8 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=3 # This GPU is mapped on /dev/nvidia3
oarnodesetting -a -h 'clustera-2.fakesite.grid5000.fr' -p host='clustera-2.fakesite.grid5000.fr' -p cpu=4 -p core=30 -p cpuset=11 -p gpu=8 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=3 # This GPU is mapped on /dev/nvidia3
oarnodesetting -a -h 'clustera-2.fakesite.grid5000.fr' -p host='clustera-2.fakesite.grid5000.fr' -p cpu=4 -p core=31 -p cpuset=13 -p gpu=8 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=3 # This GPU is mapped on /dev/nvidia3
oarnodesetting -a -h 'clustera-2.fakesite.grid5000.fr' -p host='clustera-2.fakesite.grid5000.fr' -p cpu=4 -p core=32 -p cpuset=15 -p gpu=8 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=3 # This GPU is mapped on /dev/nvidia3
      TXT
      expected_clustera3_cmds = <<-TXT
oarnodesetting --sql "host='clustera-2.fakesite.grid5000.fr' and type='default'" -p ip='172.16.64.2' -p cluster='clustera' -p nodemodel='Dell PowerEdge T640' -p switch='gw-fakesite' -p besteffort='YES' -p deploy='YES' -p virtual='ivt' -p cpuarch='x86_64' -p cpucore=8 -p cputype='Intel Xeon Silver 4110' -p cpufreq='2.1' -p disktype='SATA' -p chassis='Dell Inc. PowerEdge T640 9L1CBX2' -p eth_count=1 -p eth_rate=10 -p ib_count=0 -p ib_rate=0 -p ib='NO' -p opa_count=0 -p opa_rate=0 -p myri_count=0 -p myri_rate=0 -p myri='NO' -p memcore=8192 -p memcpu=65536 -p memnode=131072 -p gpu_count=4 -p exotic='NO' -p mic='NO' -p wattmeter='MULTIPLE' -p cluster_priority=201906 -p max_walltime=86400 -p production='YES' -p maintenance='NO' -p disk_reservation_count=0
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
    ["+", "besteffort", "YES"]
    ["+", "chassis", "Dell Inc. PowerEdge T640 FL1CBX2"]
    ["+", "cluster", "clustera"]
    ["+", "cluster_priority", 201906]
    ["+", "cpuarch", "x86_64"]
    ["+", "cpucore", 8]
    ["+", "cpufreq", "2.1"]
    ["+", "cputype", "Intel Xeon Silver 4110"]
    ["+", "deploy", "YES"]
    ["+", "disk_reservation_count", 0]
    ["+", "disktype", "SATA"]
    ["+", "eth_count", 1]
    ["+", "eth_rate", 10]
    ["+", "exotic", "NO"]
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
    ["+", "opa_count", 0]
    ["+", "opa_rate", 0]
    ["+", "production", "YES"]
    ["+", "switch", "gw-fakesite"]
    ["+", "virtual", "ivt"]
    ["+", "wattmeter", "MULTIPLE"]
      TXT

      expected_clustera2_diff = <<-TXT
  clustera-2: new node !
    ["+", "besteffort", "YES"]
    ["+", "chassis", "Dell Inc. PowerEdge T640 9L1CBX2"]
    ["+", "cluster", "clustera"]
    ["+", "cluster_priority", 201906]
    ["+", "cpuarch", "x86_64"]
    ["+", "cpucore", 8]
    ["+", "cpufreq", "2.1"]
    ["+", "cputype", "Intel Xeon Silver 4110"]
    ["+", "deploy", "YES"]
    ["+", "disk_reservation_count", 0]
    ["+", "disktype", "SATA"]
    ["+", "eth_count", 1]
    ["+", "eth_rate", 10]
    ["+", "exotic", "NO"]
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

  context 'interracting with an empty OAR server (contiguous_including_threads cpusets)' do
    before do
      prepare_stubs("dump_oar_api_empty_server.json", "load_data_hierarchy_stubbed_data_contiguous-including-threads_cpusets.json")
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

      expected_clustera1_begin_desc = <<-TXT
|  clustera | clustera-1           | 1     | 1     | 0        |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-1           | 1     | 2     | 1        |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-1           | 1     | 3     | 2        |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-1           | 1     | 4     | 3        |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-1           | 1     | 5     | 4        |      |                      | ThunderX2 99xx                 |                               |
      TXT


      expected_clustera1_middle_desc = <<-TXT
|  clustera | clustera-1           | 1     | 29    | 28       |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-1           | 1     | 30    | 29       |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-1           | 1     | 31    | 30       |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-1           | 1     | 32    | 31       |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-1           | 2     | 33    | 128      |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-1           | 2     | 34    | 129      |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-1           | 2     | 35    | 130      |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-1           | 2     | 36    | 131      |      |                      | ThunderX2 99xx                 |                               |
      TXT

      expected_clustera2_middle_desc = <<-TXT
|  clustera | clustera-2           | 3     | 93    | 28       |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-2           | 3     | 94    | 29       |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-2           | 3     | 95    | 30       |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-2           | 3     | 96    | 31       |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-2           | 4     | 97    | 128      |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-2           | 4     | 98    | 129      |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-2           | 4     | 99    | 130      |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-2           | 4     | 100   | 131      |      |                      | ThunderX2 99xx                 |                               |
      TXT

      expected_clustera2_end_desc = <<-TXT
|  clustera | clustera-2           | 4     | 125   | 156      |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-2           | 4     | 126   | 157      |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-2           | 4     | 127   | 158      |      |                      | ThunderX2 99xx                 |                               |
|  clustera | clustera-2           | 4     | 128   | 159      |      |                      | ThunderX2 99xx                 |                               |
+---------- + -------------------- + ----- + ----- + -------- + ---- + -------------------- + ------------------------------ + ------------------------------+
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_header)
      expect(generator_output[:stdout]).to include(expected_clustera1_begin_desc)
      expect(generator_output[:stdout]).to include(expected_clustera1_middle_desc)
      expect(generator_output[:stdout]).to include(expected_clustera2_middle_desc)
      expect(generator_output[:stdout]).to include(expected_clustera2_end_desc)
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
oarnodesetting -a -h 'clustera-1.fakesite.grid5000.fr' -p host='clustera-1.fakesite.grid5000.fr' -p cpu=1 -p core=29 -p cpuset=28
oarnodesetting -a -h 'clustera-1.fakesite.grid5000.fr' -p host='clustera-1.fakesite.grid5000.fr' -p cpu=1 -p core=30 -p cpuset=29
oarnodesetting -a -h 'clustera-1.fakesite.grid5000.fr' -p host='clustera-1.fakesite.grid5000.fr' -p cpu=1 -p core=31 -p cpuset=30
oarnodesetting -a -h 'clustera-1.fakesite.grid5000.fr' -p host='clustera-1.fakesite.grid5000.fr' -p cpu=1 -p core=32 -p cpuset=31
oarnodesetting -a -h 'clustera-1.fakesite.grid5000.fr' -p host='clustera-1.fakesite.grid5000.fr' -p cpu=2 -p core=33 -p cpuset=128
oarnodesetting -a -h 'clustera-1.fakesite.grid5000.fr' -p host='clustera-1.fakesite.grid5000.fr' -p cpu=2 -p core=34 -p cpuset=129
oarnodesetting -a -h 'clustera-1.fakesite.grid5000.fr' -p host='clustera-1.fakesite.grid5000.fr' -p cpu=2 -p core=35 -p cpuset=130
oarnodesetting -a -h 'clustera-1.fakesite.grid5000.fr' -p host='clustera-1.fakesite.grid5000.fr' -p cpu=2 -p core=36 -p cpuset=131
      TXT

      expected_clustera2_cmds = <<-TXT
oarnodesetting -a -h 'clustera-2.fakesite.grid5000.fr' -p host='clustera-2.fakesite.grid5000.fr' -p cpu=3 -p core=93 -p cpuset=28
oarnodesetting -a -h 'clustera-2.fakesite.grid5000.fr' -p host='clustera-2.fakesite.grid5000.fr' -p cpu=3 -p core=94 -p cpuset=29
oarnodesetting -a -h 'clustera-2.fakesite.grid5000.fr' -p host='clustera-2.fakesite.grid5000.fr' -p cpu=3 -p core=95 -p cpuset=30
oarnodesetting -a -h 'clustera-2.fakesite.grid5000.fr' -p host='clustera-2.fakesite.grid5000.fr' -p cpu=3 -p core=96 -p cpuset=31
oarnodesetting -a -h 'clustera-2.fakesite.grid5000.fr' -p host='clustera-2.fakesite.grid5000.fr' -p cpu=4 -p core=97 -p cpuset=128
oarnodesetting -a -h 'clustera-2.fakesite.grid5000.fr' -p host='clustera-2.fakesite.grid5000.fr' -p cpu=4 -p core=98 -p cpuset=129
oarnodesetting -a -h 'clustera-2.fakesite.grid5000.fr' -p host='clustera-2.fakesite.grid5000.fr' -p cpu=4 -p core=99 -p cpuset=130
oarnodesetting -a -h 'clustera-2.fakesite.grid5000.fr' -p host='clustera-2.fakesite.grid5000.fr' -p cpu=4 -p core=100 -p cpuset=131
      TXT

      expected_clustera3_cmds = <<-TXT
oarnodesetting --sql "host='clustera-2.fakesite.grid5000.fr' and type='default'" -p ip='172.16.54.2' -p cluster='clustera' -p nodemodel='Dell PowerEdge T640' -p switch='gw' -p besteffort='YES' -p deploy='YES' -p virtual='arm64' -p cpuarch='aarch64' -p cpucore=32 -p cputype='ThunderX2 99xx' -p cpufreq='2.2' -p disktype='SAS' -p chassis='GIGABYTE R181-T92-00 GJG5N9812A0004' -p eth_count=1 -p eth_rate=10 -p ib_count=0 -p ib_rate=0 -p ib='NO' -p opa_count=0 -p opa_rate=0 -p myri_count=0 -p myri_rate=0 -p myri='NO' -p memcore=4096 -p memcpu=131072 -p memnode=262144 -p gpu_count=0 -p exotic='NO' -p mic='NO' -p wattmeter='NO' -p cluster_priority=201906 -p max_walltime=0 -p production='NO' -p maintenance='YES' -p disk_reservation_count=0
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_header)
      expect(generator_output[:stdout]).to include(expected_clustera1_cmds)
      expect(generator_output[:stdout]).to include(expected_clustera2_cmds)
      expect(generator_output[:stdout]).to include(expected_clustera3_cmds)
    end
  end

  context 'interracting with an empty OAR server (cluster with disk)' do
    before do
      prepare_stubs("dump_oar_api_empty_server.json", "load_data_hierarchy_stubbed_data_with_disk.json")
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
          :clusters => ["clusterb"]
      }

      expected_header = <<-TXT
+---------- + -------------------- + ----- + ----- + -------- + ---- + -------------------- + ------------------------------ + ------------------------------+
|   cluster | host                 | cpu   | core  | cpuset   | gpu  | gpudevice            | cpumodel                       | gpumodel                      |
+---------- + -------------------- + ----- + ----- + -------- + ---- + -------------------- + ------------------------------ + ------------------------------+
TXT

      expected_clusterb1_desc = <<-TXT
|  clusterb | clusterb-1           | 1     | 1     | 0        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-1           | 1     | 2     | 1        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-1           | 1     | 3     | 2        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-1           | 1     | 4     | 3        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-1           | 1     | 5     | 4        | 2    | 1                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-1           | 1     | 6     | 5        | 2    | 1                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-1           | 1     | 7     | 6        | 2    | 1                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
TXT

      expected_clusterb2_desc = <<-TXT
|  clusterb | clusterb-2           | 3     | 17    | 0        | 5    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-2           | 3     | 18    | 1        | 5    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-2           | 3     | 19    | 2        | 5    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-2           | 3     | 20    | 3        | 5    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-2           | 3     | 21    | 4        | 6    | 1                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-2           | 3     | 22    | 5        | 6    | 1                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-2           | 3     | 23    | 6        | 6    | 1                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_header)
      expect(generator_output[:stdout]).to include(expected_clusterb1_desc)
      expect(generator_output[:stdout]).to include(expected_clusterb2_desc)
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
          :clusters => ["clusterb"]
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

      expected_clusterb1_cmds = <<-TXT
###################################
# clusterb-1.fakesite.grid5000.fr
###################################
oarnodesetting -a -h 'clusterb-1.fakesite.grid5000.fr' -p host='clusterb-1.fakesite.grid5000.fr' -p cpu=1 -p core=1 -p cpuset=0 -p gpu=1 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting -a -h 'clusterb-1.fakesite.grid5000.fr' -p host='clusterb-1.fakesite.grid5000.fr' -p cpu=1 -p core=2 -p cpuset=1 -p gpu=1 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting -a -h 'clusterb-1.fakesite.grid5000.fr' -p host='clusterb-1.fakesite.grid5000.fr' -p cpu=1 -p core=3 -p cpuset=2 -p gpu=1 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting -a -h 'clusterb-1.fakesite.grid5000.fr' -p host='clusterb-1.fakesite.grid5000.fr' -p cpu=1 -p core=4 -p cpuset=3 -p gpu=1 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
TXT

      expected_clusterb2_cmds = <<-TXT
oarnodesetting -a -h 'clusterb-2.fakesite.grid5000.fr' -p host='clusterb-2.fakesite.grid5000.fr' -p cpu=4 -p core=25 -p cpuset=8 -p gpu=7 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=2 # This GPU is mapped on /dev/nvidia2
oarnodesetting -a -h 'clusterb-2.fakesite.grid5000.fr' -p host='clusterb-2.fakesite.grid5000.fr' -p cpu=4 -p core=26 -p cpuset=9 -p gpu=7 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=2 # This GPU is mapped on /dev/nvidia2
oarnodesetting -a -h 'clusterb-2.fakesite.grid5000.fr' -p host='clusterb-2.fakesite.grid5000.fr' -p cpu=4 -p core=27 -p cpuset=10 -p gpu=7 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=2 # This GPU is mapped on /dev/nvidia2
oarnodesetting -a -h 'clusterb-2.fakesite.grid5000.fr' -p host='clusterb-2.fakesite.grid5000.fr' -p cpu=4 -p core=28 -p cpuset=11 -p gpu=7 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=2 # This GPU is mapped on /dev/nvidia2
oarnodesetting -a -h 'clusterb-2.fakesite.grid5000.fr' -p host='clusterb-2.fakesite.grid5000.fr' -p cpu=4 -p core=29 -p cpuset=12 -p gpu=8 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=3 # This GPU is mapped on /dev/nvidia3
oarnodesetting -a -h 'clusterb-2.fakesite.grid5000.fr' -p host='clusterb-2.fakesite.grid5000.fr' -p cpu=4 -p core=30 -p cpuset=13 -p gpu=8 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=3 # This GPU is mapped on /dev/nvidia3
oarnodesetting -a -h 'clusterb-2.fakesite.grid5000.fr' -p host='clusterb-2.fakesite.grid5000.fr' -p cpu=4 -p core=31 -p cpuset=14 -p gpu=8 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=3 # This GPU is mapped on /dev/nvidia3
oarnodesetting -a -h 'clusterb-2.fakesite.grid5000.fr' -p host='clusterb-2.fakesite.grid5000.fr' -p cpu=4 -p core=32 -p cpuset=15 -p gpu=8 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=3 # This GPU is mapped on /dev/nvidia3
TXT

      expected_clusterb3_cmds = <<-TXT
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' and type='default'" -p ip='172.16.64.2' -p cluster='clusterb' -p nodemodel='Dell PowerEdge T640' -p besteffort='YES' -p deploy='YES' -p virtual='ivt' -p cpuarch='x86_64' -p cpucore=8 -p cputype='Intel Xeon Silver 4110' -p cpufreq='2.1' -p disktype='SATA' -p chassis='Dell Inc. PowerEdge T640 9L1CBX2' -p eth_count=1 -p eth_rate=10 -p ib_count=0 -p ib_rate=0 -p ib='NO' -p opa_count=0 -p opa_rate=0 -p myri_count=0 -p myri_rate=0 -p myri='NO' -p memcore=8192 -p memcpu=65536 -p memnode=131072 -p gpu_count=4 -p exotic='NO' -p mic='NO' -p wattmeter='MULTIPLE' -p cluster_priority=201906 -p max_walltime=86400 -p production='YES' -p maintenance='NO' -p disk_reservation_count=3
TXT

      expected_clusterb4_cmds = <<-TXT
echo '================================================================================'
echo; echo 'Adding disk sdd.clusterb-2 on host clusterb-2.fakesite.grid5000.fr:'
disk_exist 'clusterb-2.fakesite.grid5000.fr' 'sdd.clusterb-2' && echo '=> disk already exists'
disk_exist 'clusterb-2.fakesite.grid5000.fr' 'sdd.clusterb-2' || oarnodesetting -a -h '' -p host='clusterb-2.fakesite.grid5000.fr' -p type='disk' -p disk='sdd.clusterb-2'

echo; echo 'Setting properties for disk sdd.clusterb-2 on host clusterb-2.fakesite.grid5000.fr:'; echo
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' and type='disk' and disk='sdd.clusterb-2'" -p cluster='clusterb' -p host='clusterb-2.fakesite.grid5000.fr' -p available_upto=0 -p deploy='YES' -p production='YES' -p maintenance='NO' -p disk='sdd.clusterb-2' -p diskpath='/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:3:0' -p exotic='NO' -p cpuset=-1
TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_header)
      expect(generator_output[:stdout]).to include(expected_clusterb1_cmds)
      expect(generator_output[:stdout]).to include(expected_clusterb2_cmds)
      expect(generator_output[:stdout]).to include(expected_clusterb3_cmds)
      expect(generator_output[:stdout]).to include(expected_clusterb4_cmds)
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
          :clusters => ["clusterb"],
          :verbose => 2
      }

      expected_clusterb1_diff = <<-TXT
  clusterb-1: new node !
    ["+", "besteffort", "YES"]
    ["+", "chassis", "Dell Inc. PowerEdge T640 FL1CBX2"]
    ["+", "cluster", "clusterb"]
    ["+", "cluster_priority", 201906]
    ["+", "cpuarch", "x86_64"]
    ["+", "cpucore", 8]
    ["+", "cpufreq", "2.1"]
    ["+", "cputype", "Intel Xeon Silver 4110"]
    ["+", "deploy", "YES"]
    ["+", "disk_reservation_count", 3]
    ["+", "disktype", "SATA"]
    ["+", "eth_count", 1]
    ["+", "eth_rate", 10]
    ["+", "exotic", "NO"]
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
    ["+", "opa_count", 0]
    ["+", "opa_rate", 0]
    ["+", "production", "YES"]
    ["+", "switch", nil]
    ["+", "virtual", "ivt"]
    ["+", "wattmeter", "MULTIPLE"]
TXT

      expected_clusterb2_diff = <<-TXT
  clusterb-2: new node !
    ["+", "besteffort", "YES"]
    ["+", "chassis", "Dell Inc. PowerEdge T640 9L1CBX2"]
    ["+", "cluster", "clusterb"]
    ["+", "cluster_priority", 201906]
    ["+", "cpuarch", "x86_64"]
    ["+", "cpucore", 8]
    ["+", "cpufreq", "2.1"]
    ["+", "cputype", "Intel Xeon Silver 4110"]
    ["+", "deploy", "YES"]
    ["+", "disk_reservation_count", 3]
    ["+", "disktype", "SATA"]
    ["+", "eth_count", 1]
    ["+", "eth_rate", 10]
    ["+", "exotic", "NO"]
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
    ["+", "opa_count", 0]
    ["+", "opa_rate", 0]
    ["+", "production", "YES"]
    ["+", "switch", nil]
    ["+", "virtual", "ivt"]
    ["+", "wattmeter", "MULTIPLE"]
TXT

      expected_clusterb3_diff =  <<-TXT
  ["clusterb-1", "sdb.clusterb-1"]: new disk !
    ["+", "available_upto", 0]
    ["+", "cluster", "clusterb"]
    ["+", "cpuset", -1]
    ["+", "deploy", "YES"]
    ["+", "disk", "sdb.clusterb-1"]
    ["+", "diskpath", "/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:1:0"]
    ["+", "host", "clusterb-1.fakesite.grid5000.fr"]
    ["+", "maintenance", "NO"]
    ["+", "network_address", ""]
    ["+", "production", "YES"]
  ["clusterb-1", "sdc.clusterb-1"]: new disk !
    ["+", "available_upto", 0]
    ["+", "cluster", "clusterb"]
    ["+", "cpuset", -1]
    ["+", "deploy", "YES"]
    ["+", "disk", "sdc.clusterb-1"]
    ["+", "diskpath", "/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:2:0"]
    ["+", "host", "clusterb-1.fakesite.grid5000.fr"]
    ["+", "maintenance", "NO"]
    ["+", "network_address", ""]
    ["+", "production", "YES"]
  ["clusterb-1", "sdd.clusterb-1"]: new disk !
    ["+", "available_upto", 0]
    ["+", "cluster", "clusterb"]
    ["+", "cpuset", -1]
    ["+", "deploy", "YES"]
    ["+", "disk", "sdd.clusterb-1"]
    ["+", "diskpath", "/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:3:0"]
    ["+", "host", "clusterb-1.fakesite.grid5000.fr"]
    ["+", "maintenance", "NO"]
    ["+", "network_address", ""]
    ["+", "production", "YES"]
  ["clusterb-2", "sdb.clusterb-2"]: new disk !
    ["+", "available_upto", 0]
    ["+", "cluster", "clusterb"]
    ["+", "cpuset", -1]
    ["+", "deploy", "YES"]
    ["+", "disk", "sdb.clusterb-2"]
    ["+", "diskpath", "/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:1:0"]
    ["+", "host", "clusterb-2.fakesite.grid5000.fr"]
    ["+", "maintenance", "NO"]
    ["+", "network_address", ""]
    ["+", "production", "YES"]
  ["clusterb-2", "sdc.clusterb-2"]: new disk !
    ["+", "available_upto", 0]
    ["+", "cluster", "clusterb"]
    ["+", "cpuset", -1]
    ["+", "deploy", "YES"]
    ["+", "disk", "sdc.clusterb-2"]
    ["+", "diskpath", "/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:2:0"]
    ["+", "host", "clusterb-2.fakesite.grid5000.fr"]
    ["+", "maintenance", "NO"]
    ["+", "network_address", ""]
    ["+", "production", "YES"]
  ["clusterb-2", "sdd.clusterb-2"]: new disk !
    ["+", "available_upto", 0]
    ["+", "cluster", "clusterb"]
    ["+", "cpuset", -1]
    ["+", "deploy", "YES"]
    ["+", "disk", "sdd.clusterb-2"]
    ["+", "diskpath", "/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:3:0"]
    ["+", "host", "clusterb-2.fakesite.grid5000.fr"]
    ["+", "maintenance", "NO"]
    ["+", "network_address", ""]
    ["+", "production", "YES"]
TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_clusterb1_diff)
      expect(generator_output[:stdout]).to include(expected_clusterb2_diff)
      expect(generator_output[:stdout]).to include(expected_clusterb3_diff)
    end
  end



  context 'OAR server with data (cluster with disk)' do
    before do
      prepare_stubs("dump_oar_api_configured_server_with_disk.json", "load_data_hierarchy_stubbed_data_with_disk.json")
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
          :clusters => ["clusterb"]
      }

      expected_header = <<-TXT
+---------- + -------------------- + ----- + ----- + -------- + ---- + -------------------- + ------------------------------ + ------------------------------+
|   cluster | host                 | cpu   | core  | cpuset   | gpu  | gpudevice            | cpumodel                       | gpumodel                      |
+---------- + -------------------- + ----- + ----- + -------- + ---- + -------------------- + ------------------------------ + ------------------------------+
TXT

      expected_clusterb1_desc = <<-TXT
|  clusterb | clusterb-1           | 1     | 1     | 0        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-1           | 1     | 2     | 1        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-1           | 1     | 3     | 2        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-1           | 1     | 4     | 3        | 1    | 0                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-1           | 1     | 5     | 4        | 2    | 1                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-1           | 1     | 6     | 5        | 2    | 1                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
TXT

      expected_clusterb2_desc = <<-TXT
|  clusterb | clusterb-2           | 4     | 26    | 9        | 7    | 2                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-2           | 4     | 27    | 10       | 7    | 2                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-2           | 4     | 28    | 11       | 7    | 2                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-2           | 4     | 29    | 12       | 8    | 3                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-2           | 4     | 30    | 13       | 8    | 3                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-2           | 4     | 31    | 14       | 8    | 3                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
|  clusterb | clusterb-2           | 4     | 32    | 15       | 8    | 3                    | Intel Xeon Silver 4110         | GeForce RTX 2080 Ti           |
TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_header)
      expect(generator_output[:stdout]).to include(expected_clusterb1_desc)
      expect(generator_output[:stdout]).to include(expected_clusterb2_desc)
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
          :clusters => ["clusterb"]
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

      expected_clusterb1_cmds = <<-TXT
###################################
# clusterb-1.fakesite.grid5000.fr
###################################
oarnodesetting --sql "host='clusterb-1.fakesite.grid5000.fr' AND resource_id='1' AND type='default'" -p cpu=1 -p core=1 -p cpuset=0 -p gpu=1 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting --sql "host='clusterb-1.fakesite.grid5000.fr' AND resource_id='2' AND type='default'" -p cpu=1 -p core=2 -p cpuset=1 -p gpu=1 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting --sql "host='clusterb-1.fakesite.grid5000.fr' AND resource_id='3' AND type='default'" -p cpu=1 -p core=3 -p cpuset=2 -p gpu=1 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting --sql "host='clusterb-1.fakesite.grid5000.fr' AND resource_id='4' AND type='default'" -p cpu=1 -p core=4 -p cpuset=3 -p gpu=1 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
TXT

      expected_clusterb2_cmds = <<-TXT
###################################
# clusterb-2.fakesite.grid5000.fr
###################################
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' AND resource_id='20' AND type='default'" -p cpu=3 -p core=17 -p cpuset=0 -p gpu=5 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' AND resource_id='21' AND type='default'" -p cpu=3 -p core=18 -p cpuset=1 -p gpu=5 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' AND resource_id='22' AND type='default'" -p cpu=3 -p core=19 -p cpuset=2 -p gpu=5 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' AND resource_id='23' AND type='default'" -p cpu=3 -p core=20 -p cpuset=3 -p gpu=5 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=0 # This GPU is mapped on /dev/nvidia0
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' AND resource_id='24' AND type='default'" -p cpu=3 -p core=21 -p cpuset=4 -p gpu=6 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=1 # This GPU is mapped on /dev/nvidia1
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' AND resource_id='25' AND type='default'" -p cpu=3 -p core=22 -p cpuset=5 -p gpu=6 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=1 # This GPU is mapped on /dev/nvidia1
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' AND resource_id='26' AND type='default'" -p cpu=3 -p core=23 -p cpuset=6 -p gpu=6 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=1 # This GPU is mapped on /dev/nvidia1
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' AND resource_id='27' AND type='default'" -p cpu=3 -p core=24 -p cpuset=7 -p gpu=6 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=1 # This GPU is mapped on /dev/nvidia1
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' AND resource_id='28' AND type='default'" -p cpu=4 -p core=25 -p cpuset=8 -p gpu=7 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=2 # This GPU is mapped on /dev/nvidia2
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' AND resource_id='29' AND type='default'" -p cpu=4 -p core=26 -p cpuset=9 -p gpu=7 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=2 # This GPU is mapped on /dev/nvidia2
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' AND resource_id='30' AND type='default'" -p cpu=4 -p core=27 -p cpuset=10 -p gpu=7 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=2 # This GPU is mapped on /dev/nvidia2
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' AND resource_id='31' AND type='default'" -p cpu=4 -p core=28 -p cpuset=11 -p gpu=7 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=2 # This GPU is mapped on /dev/nvidia2
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' AND resource_id='32' AND type='default'" -p cpu=4 -p core=29 -p cpuset=12 -p gpu=8 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=3 # This GPU is mapped on /dev/nvidia3
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' AND resource_id='33' AND type='default'" -p cpu=4 -p core=30 -p cpuset=13 -p gpu=8 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=3 # This GPU is mapped on /dev/nvidia3
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' AND resource_id='34' AND type='default'" -p cpu=4 -p core=31 -p cpuset=14 -p gpu=8 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=3 # This GPU is mapped on /dev/nvidia3
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' AND resource_id='35' AND type='default'" -p cpu=4 -p core=32 -p cpuset=15 -p gpu=8 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=3 # This GPU is mapped on /dev/nvidia3
TXT

      expected_clusterb3_cmds = <<-TXT
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' and type='default'" -p ip='172.16.64.2' -p cluster='clusterb' -p nodemodel='Dell PowerEdge T640' -p besteffort='YES' -p deploy='YES' -p virtual='ivt' -p cpuarch='x86_64' -p cpucore=8 -p cputype='Intel Xeon Silver 4110' -p cpufreq='2.1' -p disktype='SATA' -p chassis='Dell Inc. PowerEdge T640 9L1CBX2' -p eth_count=1 -p eth_rate=10 -p ib_count=0 -p ib_rate=0 -p ib='NO' -p opa_count=0 -p opa_rate=0 -p myri_count=0 -p myri_rate=0 -p myri='NO' -p memcore=8192 -p memcpu=65536 -p memnode=131072 -p gpu_count=4 -p exotic='NO' -p mic='NO' -p wattmeter='MULTIPLE' -p cluster_priority=201906 -p max_walltime=86400 -p production='YES' -p maintenance='NO' -p disk_reservation_count=3
TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_header)
      expect(generator_output[:stdout]).to include(expected_clusterb1_cmds)
      expect(generator_output[:stdout]).to include(expected_clusterb2_cmds)
      expect(generator_output[:stdout]).to include(expected_clusterb3_cmds)
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
          :clusters => ["clusterb"],
          :verbose => 2
      }

      expected_clusterb1_diff = <<-TXT
  clusterb-1: OK
TXT

      expected_clusterb2_diff = <<-TXT
  clusterb-2: OK
TXT

      expected_clusterb3_diff = <<-TXT
  ["clusterb-1", "sdb.clusterb-1"]: OK
  ["clusterb-1", "sdc.clusterb-1"]: OK
  ["clusterb-1", "sdd.clusterb-1"]: OK
  ["clusterb-2", "sdb.clusterb-2"]: OK
  ["clusterb-2", "sdc.clusterb-2"]: OK
  ["clusterb-2", "sdd.clusterb-2"]: OK
TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_clusterb1_diff)
      expect(generator_output[:stdout]).to include(expected_clusterb2_diff)
      expect(generator_output[:stdout]).to include(expected_clusterb3_diff)
    end
  end

  context 'interracting with an empty OAR server (without gpu)' do
    before do
      prepare_stubs("dump_oar_api_empty_server.json", "load_data_hierarchy_stubbed_data_without_gpu.json")
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
          :clusters => ["clusterc"]
      }

      expected_header = <<-TXT
+---------- + -------------------- + ----- + ----- + -------- + ---- + -------------------- + ------------------------------ + ------------------------------+
|   cluster | host                 | cpu   | core  | cpuset   | gpu  | gpudevice            | cpumodel                       | gpumodel                      |
+---------- + -------------------- + ----- + ----- + -------- + ---- + -------------------- + ------------------------------ + ------------------------------+
TXT

      expected_clusterc1_desc = <<-TXT
|  clusterc | clusterc-1           | 1     | 1     | 0        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-1           | 1     | 2     | 1        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-1           | 1     | 3     | 2        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-1           | 1     | 4     | 3        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-1           | 1     | 5     | 4        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-1           | 1     | 6     | 5        |      |                      | Intel Xeon Silver 4110         |                               |
TXT

      expected_clusterc2_desc = <<-TXT
|  clusterc | clusterc-2           | 4     | 26    | 9        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-2           | 4     | 27    | 10       |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-2           | 4     | 28    | 11       |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-2           | 4     | 29    | 12       |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-2           | 4     | 30    | 13       |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-2           | 4     | 31    | 14       |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-2           | 4     | 32    | 15       |      |                      | Intel Xeon Silver 4110         |                               |
TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_header)
      expect(generator_output[:stdout]).to include(expected_clusterc1_desc)
      expect(generator_output[:stdout]).to include(expected_clusterc2_desc)
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
          :clusters => ["clusterc"]
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

      expected_clusterc1_cmds = <<-TXT
###################################
# clusterc-1.fakesite.grid5000.fr
###################################
oarnodesetting -a -h 'clusterc-1.fakesite.grid5000.fr' -p host='clusterc-1.fakesite.grid5000.fr' -p cpu=1 -p core=1 -p cpuset=0
oarnodesetting -a -h 'clusterc-1.fakesite.grid5000.fr' -p host='clusterc-1.fakesite.grid5000.fr' -p cpu=1 -p core=2 -p cpuset=1
oarnodesetting -a -h 'clusterc-1.fakesite.grid5000.fr' -p host='clusterc-1.fakesite.grid5000.fr' -p cpu=1 -p core=3 -p cpuset=2
TXT



      expected_clusterc2_cmds = <<-TXT
oarnodesetting -a -h 'clusterc-2.fakesite.grid5000.fr' -p host='clusterc-2.fakesite.grid5000.fr' -p cpu=4 -p core=29 -p cpuset=12
oarnodesetting -a -h 'clusterc-2.fakesite.grid5000.fr' -p host='clusterc-2.fakesite.grid5000.fr' -p cpu=4 -p core=30 -p cpuset=13
oarnodesetting -a -h 'clusterc-2.fakesite.grid5000.fr' -p host='clusterc-2.fakesite.grid5000.fr' -p cpu=4 -p core=31 -p cpuset=14
oarnodesetting -a -h 'clusterc-2.fakesite.grid5000.fr' -p host='clusterc-2.fakesite.grid5000.fr' -p cpu=4 -p core=32 -p cpuset=15
TXT
      expected_clusterc3_cmds = <<-TXT
oarnodesetting --sql "host='clusterc-2.fakesite.grid5000.fr' and type='default'" -p ip='172.16.64.2' -p cluster='clusterc' -p nodemodel='Dell PowerEdge T640' -p besteffort='YES' -p deploy='YES' -p virtual='ivt' -p cpuarch='x86_64' -p cpucore=8 -p cputype='Intel Xeon Silver 4110' -p cpufreq='2.1' -p disktype='SATA' -p chassis='Dell Inc. PowerEdge T640 9L1CBX2' -p eth_count=1 -p eth_rate=10 -p ib_count=0 -p ib_rate=0 -p ib='NO' -p opa_count=0 -p opa_rate=0 -p myri_count=0 -p myri_rate=0 -p myri='NO' -p memcore=8192 -p memcpu=65536 -p memnode=131072 -p gpu_count=0 -p exotic='NO' -p mic='NO' -p wattmeter='MULTIPLE' -p cluster_priority=201906 -p max_walltime=86400 -p production='YES' -p maintenance='NO' -p disk_reservation_count=3
TXT


      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_header)
      expect(generator_output[:stdout]).to include(expected_clusterc1_cmds)
      expect(generator_output[:stdout]).to include(expected_clusterc2_cmds)
      expect(generator_output[:stdout]).to include(expected_clusterc3_cmds)
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
          :clusters => ["clusterc"],
          :verbose => 2
      }

      expected_clusterc1_diff = <<-TXT
  clusterc-1: new node !
    ["+", "besteffort", "YES"]
    ["+", "chassis", "Dell Inc. PowerEdge T640 FL1CBX2"]
    ["+", "cluster", "clusterc"]
    ["+", "cluster_priority", 201906]
    ["+", "cpuarch", "x86_64"]
    ["+", "cpucore", 8]
    ["+", "cpufreq", "2.1"]
    ["+", "cputype", "Intel Xeon Silver 4110"]
    ["+", "deploy", "YES"]
    ["+", "disk_reservation_count", 3]
    ["+", "disktype", "SATA"]
    ["+", "eth_count", 1]
    ["+", "eth_rate", 10]
    ["+", "exotic", "NO"]
    ["+", "gpu_count", 0]
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
    ["+", "opa_count", 0]
    ["+", "opa_rate", 0]
    ["+", "production", "YES"]
    ["+", "switch", nil]
    ["+", "virtual", "ivt"]
    ["+", "wattmeter", "MULTIPLE"]
TXT

      expected_clusterc2_diff = <<-TXT
  clusterc-2: new node !
    ["+", "besteffort", "YES"]
    ["+", "chassis", "Dell Inc. PowerEdge T640 9L1CBX2"]
    ["+", "cluster", "clusterc"]
    ["+", "cluster_priority", 201906]
    ["+", "cpuarch", "x86_64"]
    ["+", "cpucore", 8]
    ["+", "cpufreq", "2.1"]
    ["+", "cputype", "Intel Xeon Silver 4110"]
    ["+", "deploy", "YES"]
    ["+", "disk_reservation_count", 3]
    ["+", "disktype", "SATA"]
    ["+", "eth_count", 1]
    ["+", "eth_rate", 10]
    ["+", "exotic", "NO"]
    ["+", "gpu_count", 0]
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
    ["+", "opa_count", 0]
    ["+", "opa_rate", 0]
    ["+", "production", "YES"]
    ["+", "switch", nil]
    ["+", "virtual", "ivt"]
    ["+", "wattmeter", "MULTIPLE"]
TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_clusterc1_diff)
      expect(generator_output[:stdout]).to include(expected_clusterc2_diff)
    end
  end

  context 'interracting with a configured OAR server (without gpu)' do
    before do
      prepare_stubs("dump_oar_api_configured_server_without_gpu.json", "load_data_hierarchy_stubbed_data_without_gpu.json")
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
          :clusters => ["clusterc"]
      }

      expected_header = <<-TXT
+---------- + -------------------- + ----- + ----- + -------- + ---- + -------------------- + ------------------------------ + ------------------------------+
|   cluster | host                 | cpu   | core  | cpuset   | gpu  | gpudevice            | cpumodel                       | gpumodel                      |
+---------- + -------------------- + ----- + ----- + -------- + ---- + -------------------- + ------------------------------ + ------------------------------+
TXT

      expected_clusterc1_desc = <<-TXT
|  clusterc | clusterc-1           | 1     | 1     | 0        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-1           | 1     | 2     | 1        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-1           | 1     | 3     | 2        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-1           | 1     | 4     | 3        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-1           | 1     | 5     | 4        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-1           | 1     | 6     | 5        |      |                      | Intel Xeon Silver 4110         |                               |
TXT

      expected_clusterc2_desc = <<-TXT
|  clusterc | clusterc-2           | 4     | 26    | 9        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-2           | 4     | 27    | 10       |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-2           | 4     | 28    | 11       |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-2           | 4     | 29    | 12       |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-2           | 4     | 30    | 13       |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-2           | 4     | 31    | 14       |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-2           | 4     | 32    | 15       |      |                      | Intel Xeon Silver 4110         |                               |
TXT
      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_header)
      expect(generator_output[:stdout]).to include(expected_clusterc1_desc)
      expect(generator_output[:stdout]).to include(expected_clusterc2_desc)
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
          :clusters => ["clusterc"]
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

      expected_clusterc1_cmds = <<-TXT
###################################
# clusterc-1.fakesite.grid5000.fr
###################################
oarnodesetting --sql "host='clusterc-1.fakesite.grid5000.fr' AND resource_id='1' AND type='default'" -p cpu=1 -p core=1 -p cpuset=0
oarnodesetting --sql "host='clusterc-1.fakesite.grid5000.fr' AND resource_id='2' AND type='default'" -p cpu=1 -p core=2 -p cpuset=1
oarnodesetting --sql "host='clusterc-1.fakesite.grid5000.fr' AND resource_id='3' AND type='default'" -p cpu=1 -p core=3 -p cpuset=2
TXT

      expected_clusterc2_cmds = <<-TXT
oarnodesetting --sql "host='clusterc-2.fakesite.grid5000.fr' AND resource_id='32' AND type='default'" -p cpu=4 -p core=29 -p cpuset=12
oarnodesetting --sql "host='clusterc-2.fakesite.grid5000.fr' AND resource_id='33' AND type='default'" -p cpu=4 -p core=30 -p cpuset=13
oarnodesetting --sql "host='clusterc-2.fakesite.grid5000.fr' AND resource_id='34' AND type='default'" -p cpu=4 -p core=31 -p cpuset=14
oarnodesetting --sql "host='clusterc-2.fakesite.grid5000.fr' AND resource_id='35' AND type='default'" -p cpu=4 -p core=32 -p cpuset=15
TXT
      expected_clusterc3_cmds = <<-TXT
oarnodesetting --sql "host='clusterc-2.fakesite.grid5000.fr' and type='default'" -p ip='172.16.64.2' -p cluster='clusterc' -p nodemodel='Dell PowerEdge T640' -p besteffort='YES' -p deploy='YES' -p virtual='ivt' -p cpuarch='x86_64' -p cpucore=8 -p cputype='Intel Xeon Silver 4110' -p cpufreq='2.1' -p disktype='SATA' -p chassis='Dell Inc. PowerEdge T640 9L1CBX2' -p eth_count=1 -p eth_rate=10 -p ib_count=0 -p ib_rate=0 -p ib='NO' -p opa_count=0 -p opa_rate=0 -p myri_count=0 -p myri_rate=0 -p myri='NO' -p memcore=8192 -p memcpu=65536 -p memnode=131072 -p gpu_count=0 -p exotic='NO' -p mic='NO' -p wattmeter='MULTIPLE' -p cluster_priority=201906 -p max_walltime=86400 -p production='YES' -p maintenance='NO' -p disk_reservation_count=3
TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_header)
      expect(generator_output[:stdout]).to include(expected_clusterc1_cmds)
      expect(generator_output[:stdout]).to include(expected_clusterc2_cmds)
      expect(generator_output[:stdout]).to include(expected_clusterc3_cmds)
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
          :clusters => ["clusterc"],
          :verbose => 2
      }

      expected_clusterc1_diff = <<-TXT
Output format: [ '-', 'key', 'value'] for missing, [ '+', 'key', 'value'] for added, ['~', 'key', 'old value', 'new value'] for changed
  clusterc-1: OK
  clusterc-2: OK
  ["clusterc-1", "sdb.clusterc-1"]: OK
  ["clusterc-1", "sdc.clusterc-1"]: OK
  ["clusterc-1", "sdd.clusterc-1"]: OK
  ["clusterc-2", "sdb.clusterc-2"]: OK
  ["clusterc-2", "sdc.clusterc-2"]: OK
  ["clusterc-2", "sdd.clusterc-2"]: OK
TXT


      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_clusterc1_diff)
    end
  end

  context 'interracting with a configured OAR server (quirk cluster)' do
    before do
      prepare_stubs("dump_oar_api_configured_server_quirk_cluster.json", "load_data_hierarchy_stubbed_data_without_gpu.json")
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
        :clusters => ["clusterc"]
      }

      expected_header = <<-TXT
+---------- + -------------------- + ----- + ----- + -------- + ---- + -------------------- + ------------------------------ + ------------------------------+
|   cluster | host                 | cpu   | core  | cpuset   | gpu  | gpudevice            | cpumodel                       | gpumodel                      |
+---------- + -------------------- + ----- + ----- + -------- + ---- + -------------------- + ------------------------------ + ------------------------------+
      TXT

      expected_clusterc1_desc = <<-TXT
|  clusterc | clusterc-1           | 1     | 1     | 0        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-1           | 1     | 2     | 1        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-1           | 1     | 3     | 2        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-1           | 1     | 4     | 3        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-1           | 1     | 5     | 4        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-1           | 1     | 6     | 5        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-1           | 1     | 7     | 6        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-1           | 1     | 8     | 7        |      |                      | Intel Xeon Silver 4110         |                               |
      TXT

      expected_clusterc2_desc = <<-TXT
|  clusterc | clusterc-2           | 4     | 26    | 9        |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-2           | 4     | 27    | 10       |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-2           | 4     | 28    | 11       |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-2           | 4     | 29    | 12       |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-2           | 4     | 30    | 13       |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-2           | 4     | 31    | 14       |      |                      | Intel Xeon Silver 4110         |                               |
|  clusterc | clusterc-2           | 4     | 32    | 15       |      |                      | Intel Xeon Silver 4110         |                               |
TXT
      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_header)
      expect(generator_output[:stdout]).to include(expected_clusterc1_desc)
      expect(generator_output[:stdout]).to include(expected_clusterc2_desc)
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
        :clusters => ["clusterc"]
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

      expected_clusterc1_cmds = <<-TXT
###################################
# clusterc-1.fakesite.grid5000.fr
###################################
oarnodesetting --sql "host='clusterc-1.fakesite.grid5000.fr' AND resource_id='1' AND type='default'" -p cpu=1 -p core=1 -p cpuset=0
oarnodesetting --sql "host='clusterc-1.fakesite.grid5000.fr' AND resource_id='3' AND type='default'" -p cpu=1 -p core=2 -p cpuset=1
oarnodesetting --sql "host='clusterc-1.fakesite.grid5000.fr' AND resource_id='2' AND type='default'" -p cpu=1 -p core=3 -p cpuset=2
TXT

      expected_clusterc2_cmds = <<-TXT
oarnodesetting --sql "host='clusterc-2.fakesite.grid5000.fr' AND resource_id='31' AND type='default'" -p cpu=4 -p core=28 -p cpuset=11
oarnodesetting --sql "host='clusterc-2.fakesite.grid5000.fr' AND resource_id='32' AND type='default'" -p cpu=4 -p core=29 -p cpuset=12
oarnodesetting --sql "host='clusterc-2.fakesite.grid5000.fr' AND resource_id='33' AND type='default'" -p cpu=4 -p core=30 -p cpuset=13
oarnodesetting --sql "host='clusterc-2.fakesite.grid5000.fr' AND resource_id='34' AND type='default'" -p cpu=4 -p core=31 -p cpuset=14
oarnodesetting --sql "host='clusterc-2.fakesite.grid5000.fr' AND resource_id='35' AND type='default'" -p cpu=4 -p core=32 -p cpuset=15
TXT
      expected_clusterc3_cmds = <<-TXT
oarnodesetting --sql "host='clusterc-2.fakesite.grid5000.fr' and type='default'" -p ip='172.16.64.2' -p cluster='clusterc' -p nodemodel='Dell PowerEdge T640' -p besteffort='YES' -p deploy='YES' -p virtual='ivt' -p cpuarch='x86_64' -p cpucore=8 -p cputype='Intel Xeon Silver 4110' -p cpufreq='2.1' -p disktype='SATA' -p chassis='Dell Inc. PowerEdge T640 9L1CBX2' -p eth_count=1 -p eth_rate=10 -p ib_count=0 -p ib_rate=0 -p ib='NO' -p opa_count=0 -p opa_rate=0 -p myri_count=0 -p myri_rate=0 -p myri='NO' -p memcore=8192 -p memcpu=65536 -p memnode=131072 -p gpu_count=0 -p exotic='NO' -p mic='NO' -p wattmeter='MULTIPLE' -p cluster_priority=201906 -p max_walltime=86400 -p production='YES' -p maintenance='NO' -p disk_reservation_count=3
TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_header)
      expect(generator_output[:stdout]).to include(expected_clusterc1_cmds)
      expect(generator_output[:stdout]).to include(expected_clusterc2_cmds)
      expect(generator_output[:stdout]).to include(expected_clusterc3_cmds)
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
        :clusters => ["clusterc"],
        :verbose => 2
      }

      expected_clusterc1_diff = <<-TXT
Output format: [ '-', 'key', 'value'] for missing, [ '+', 'key', 'value'] for added, ['~', 'key', 'old value', 'new value'] for changed
  clusterc-1: OK
  clusterc-2: OK
  ["clusterc-1", "sdb.clusterc-1"]: OK
  ["clusterc-1", "sdc.clusterc-1"]: OK
  ["clusterc-1", "sdd.clusterc-1"]: OK
  ["clusterc-2", "sdb.clusterc-2"]: OK
  ["clusterc-2", "sdc.clusterc-2"]: OK
  ["clusterc-2", "sdd.clusterc-2"]: OK
TXT


      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_clusterc1_diff)
    end
  end

  context 'interracting with a configured OAR server (misconfigured cores)' do
    before do
      prepare_stubs("dump_oar_api_configured_server_misconfigured_cores.json", "load_data_hierarchy_stubbed_data_without_gpu.json")
    end

    it 'should generate generate an error' do

      uri = URI(conf["uri"])

      response = Net::HTTP.get(uri)

      expect(response).to be_an_instance_of(String)

      options = {
        :table => false,
        :print => true,
        :update => false,
        :diff => false,
        :site => "fakesite",
        :clusters => ["clusterc"]
      }

      expected_output = <<-TXT
################################
# Error: resources with ids [2, 3] have the same value for core (core is equal to 3)
# You can review this situation via the following command:
################################
oarnodes -Y --sql "resource_id='2' OR resource_id='3'"
TXT

      generator_output = capture do
          generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_output)
    end
  end

  context 'interracting with a configured OAR server (misconfigured gpu)' do
    before do
      prepare_stubs("dump_oar_api_configured_server_misconfigured_gpu.json", "load_data_hierarchy_stubbed_data_without_gpu.json")
    end

    it 'should propose a correction' do

      uri = URI(conf["uri"])

      response = Net::HTTP.get(uri)

      expect(response).to be_an_instance_of(String)

      options = {
        :table => false,
        :print => false,
        :update => false,
        :diff => true,
        :site => "fakesite",
        :clusters => ["clustera"]
      }

      expected_output = <<-TXT
# Error: Resource 9 (host=clustera-1.fakesite.grid5000.fr cpu=2 core=9 cpuset=8 gpu=2 gpudevice=2) has a mismatch for ressource GPU: OAR API gives 2, generator wants 3.
TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_output)
    end

    it 'should print commands to correct the cluster' do

      uri = URI(conf["uri"])

      response = Net::HTTP.get(uri)

      expect(response).to be_an_instance_of(String)

      options = {
        :table => false,
        :print => false,
        :update => false,
        :diff => true,
        :site => "fakesite",
        :clusters => ["clustera"]
      }

      expected_output = <<-TXT
# Error: Resource 9 (host=clustera-1.fakesite.grid5000.fr cpu=2 core=9 cpuset=8 gpu=2 gpudevice=2) has a mismatch for ressource GPU: OAR API gives 2, generator wants 3.
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_output)
    end
  end

  context 'interracting with a configured OAR server (msising network interfaces)' do
    before do
      prepare_stubs("dump_oar_api_configured_server.json", "load_data_hierarchy_stubbed_data_missing_main_network_property.json")
    end

    it 'should propose a correction' do

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

      expected_output = <<-TXT
Error (missing property) while processing node clustera-1: Node clustera-1 does not have a main network_adapter (ie. an ethernet interface with enabled=true && mounted==true && management==false)
      TXT
      expected_output2 = <<-TXT
*** Error: The following nodes exist in the OAR server but are missing in the reference-repo: clustera-1.
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_output)
      expect(generator_output[:stdout]).to include(expected_output2)
    end
  end

  context 'interracting with a configured OAR server (wrong variable type for gpu)' do
    before do
      prepare_stubs("dump_oar_api_configured_server_wrong_vartype.json", "load_data_hierarchy_stubbed_data.json")
    end

    it 'should propose a correction' do

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

      expected_output = <<-TXT
Output format: [ '-', 'key', 'value'] for missing, [ '+', 'key', 'value'] for added, ['~', 'key', 'old value', 'new value'] for changed
  clustera-1:
    ["~", "eth_rate", "10", 10]
      TXT

      expected_output2 = <<-TXT
Error: the OAR property 'eth_rate' is a 'String' on the fakesite server and this script uses 'Integer' for this property.
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_output)
      expect(generator_output[:stdout]).to include(expected_output2)
    end
  end

  context 'interracting with a configured OAR server (different_values for wattmeters)' do
    before do
      prepare_stubs("dump_oar_api_configured_server.json", "load_data_hierarchy_stubbed_data_wattmeters_variations.json")
    end

    it 'should propose a correction' do

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

      expected_output = <<-TXT
Output format: [ '-', 'key', 'value'] for missing, [ '+', 'key', 'value'] for added, ['~', 'key', 'old value', 'new value'] for changed
  clustera-1:
    ["~", "wattmeter", "MULTIPLE", "YES"]
  clustera-2:
    ["~", "wattmeter", "MULTIPLE", "NO"]
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_output)
    end
  end

  context 'interracting with a configured OAR server (no wattmeters)' do
    before do
      prepare_stubs("dump_oar_api_configured_server.json", "load_data_hierarchy_stubbed_data_wattmeters_nil.json")
    end

    it 'should propose a correction' do

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

      expected_output = <<-TXT
Output format: [ '-', 'key', 'value'] for missing, [ '+', 'key', 'value'] for added, ['~', 'key', 'old value', 'new value'] for changed
  clustera-1:
    ["~", "wattmeter", "MULTIPLE", "NO"]
  clustera-2: same modifications as above
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_output)
    end
  end

  context 'interracting with a configured OAR server (with missing property)' do
    before do
      prepare_stubs("dump_oar_api_configured_server_missing_property.json", "load_data_hierarchy_stubbed_data.json")
    end

    it 'should propose a correction (verbose=1)' do

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
        :verbose => 1
      }

      expected_output = <<-TXT
clustera-1:["ib_rate"]
clustera-2:["ib_rate"]
Properties that need to be created on the fakesite server: ib_rate
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_output)
    end

    it 'should propose a correction (verbose=2)' do

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

      expected_output = <<-TXT
    ["+", "ib_rate", 0]
  clustera-2: same modifications as above
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_output)
    end

    it 'should propose a correction (verbose=3)' do

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
        :verbose => 3
      }

      expected_output = <<-TXT
    "new values": {
      "ip": "172.16.64.2",
      "cluster": "clustera",
      "nodemodel": "Dell PowerEdge T640",
      "switch": "gw-fakesite",
      "besteffort": "YES",
      "deploy": "YES",
      "virtual": "ivt",
      "cpuarch": "x86_64",
      "cpucore": 8,
      "cputype": "Intel Xeon Silver 4110",
      "cpufreq": "2.1",
      "disktype": "SATA",
      "chassis": "Dell Inc. PowerEdge T640 9L1CBX2",
      "eth_count": 1,
      "eth_rate": 10,
      "ib_count": 0,
      "ib_rate": 0,
      "ib": "NO",
      "opa_count": 0,
      "opa_rate": 0,
      "myri_count": 0,
      "myri_rate": 0,
      "myri": "NO",
      "memcore": 8192,
      "memcpu": 65536,
      "memnode": 131072,
      "gpu_count": 4,
      "exotic": "NO",
      "mic": "NO",
      "wattmeter": "MULTIPLE",
      "cluster_priority": 201906,
      "max_walltime": 86400,
      "production": "YES",
      "maintenance": "NO",
      "disk_reservation_count": 0
    }
  }
}
Properties that need to be created on the fakesite server: ib_rate
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_output)
    end
  end

  context 'interracting with a configured OAR server (non reservable GPUs)' do
    before do
      prepare_stubs("dump_oar_api_configured_server.json", "load_data_hierarchy_stubbed_data_with_non_reservable_gpus.json")
    end

    it 'should ignore the GPUs' do

      uri = URI(conf["uri"])

      response = Net::HTTP.get(uri)

      expect(response).to be_an_instance_of(String)

      options = {
        :table => true,
        :print => false,
        :update => false,
        :diff => false,
        :site => "fakesite",
        :clusters => ["clustera"],
        :verbose => 2
      }

      expected_output = <<-TXT
|  clustera | clustera-1           | 1     | 1     | 0        |      |                      | Intel Xeon Silver 4110         |                               |
|  clustera | clustera-1           | 1     | 2     | 1        |      |                      | Intel Xeon Silver 4110         |                               |
|  clustera | clustera-1           | 1     | 3     | 2        |      |                      | Intel Xeon Silver 4110         |                               |
|  clustera | clustera-1           | 1     | 4     | 3        |      |                      | Intel Xeon Silver 4110         |                               |
      TXT

      not_expected_output = <<-TXT
GeForce RTX 2080 Ti
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_output)
      expect(generator_output[:stdout]).not_to include(not_expected_output)
    end

    it 'it should expect no value for GPU (DIFF)' do

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

      expected_output = <<-TXT
# Error: Resource 1 (host=clustera-1.fakesite.grid5000.fr cpu=1 core=1 cpuset=0 gpu=1 gpudevice=0) has a mismatch for ressource GPU: OAR API gives 1, generator wants ø.
# Error: Resource 1 (host=clustera-1.fakesite.grid5000.fr cpu=1 core=1 cpuset=0 gpu=1 gpudevice=0) has a mismatch for ressource GPUDEVICE: OAR API gives 0, generator wants ø.
# Error: Resource 2 (host=clustera-1.fakesite.grid5000.fr cpu=1 core=2 cpuset=1 gpu=1 gpudevice=0) has a mismatch for ressource GPU: OAR API gives 1, generator wants ø.
      TXT

      not_expected_output = <<-TXT
GeForce RTX 2080 Ti
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_output)
      expect(generator_output[:stdout]).not_to include(not_expected_output)
    end
  end

  context 'interracting with a configured same CPUs, COREs, GPUS, allocated to different servers' do
    before do
      prepare_stubs("dump_oar_api_configured_server_duplicated_cpus_cores_gpus.json", "load_data_hierarchy_stubbed_data.json")
    end

    it 'should trigger an error with a message' do

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

      expected_output = <<-TXT
################################
# Error: CPU 1 is associated to more than one host: ["clustera-1.fakesite.grid5000.fr", "clustera-2.fakesite.grid5000.fr"].
# You can review this situation via the following command:
################################
oarnodes -Y --sql "cpu=1"

################################
# Error: GPU 1 is associated to more than one host: ["clustera-1.fakesite.grid5000.fr", "clustera-2.fakesite.grid5000.fr"].
# You can review this situation via the following command:
################################
oarnodes -Y --sql "gpu=1"

################################
# Error: resources with ids [21, 22] have the same value for core (core is equal to 21)
# You can review this situation via the following command:
################################
oarnodes -Y --sql "resource_id='21' OR resource_id='22'"

It seems that the cluster "clustera" has some incoherence in its resource configuration (see above). The generator will abort.
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_output)
    end
  end

  context 'interracting with a configured same CPUs, COREs, GPUS, allocated to different servers' do
    before do
      prepare_stubs("dump_oar_api_configured_server_with_too_many_oar_resources.json", "load_data_hierarchy_stubbed_data.json")
    end

    it 'should trigger an error with a message' do

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

      expected_output = <<-TXT
CORE has an unexpected number of resources (current:33 vs expected:32).
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_output)
    end
  end

  context 'interracting with a configured same CPUs, COREs, GPUS, allocated to different servers' do
    before do
      prepare_stubs("dump_oar_api_configured_server_with_too_few_oar_resources.json", "load_data_hierarchy_stubbed_data.json")
    end

    it 'should trigger an error with a message' do

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

      expected_output = <<-TXT
CORE has an unexpected number of resources (current:31 vs expected:32).
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_output)
    end
  end

  context 'interracting with a cluster with misconfigured resources, errors in its OAR properties and some misconfigured disks' do
    before do
      prepare_stubs("dump_oar_api_configured_server_with_disk_misconfigured_resources_properties_and_disks.json", "load_data_hierarchy_stubbed_data_with_disk.json")
    end

    it 'should handle "diff,print" action' do

      uri = URI(conf["uri"])

      response = Net::HTTP.get(uri)

      expect(response).to be_an_instance_of(String)

      options = {
        :table => false,
        :print => true,
        :update => false,
        :diff => true,
        :site => "fakesite",
        :clusters => ["clusterb"],
        :verbose => 2
      }

      expected_output = <<-TXT
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' and type='default'" -p ip='172.16.64.2' -p cluster='clusterb' -p nodemodel='Dell PowerEdge T640' -p besteffort='YES' -p deploy='YES' -p virtual='ivt' -p cpuarch='x86_64' -p cpucore=8 -p cputype='Intel Xeon Silver 4110' -p cpufreq='2.1' -p disktype='SATA' -p chassis='Dell Inc. PowerEdge T640 9L1CBX2' -p eth_count=1 -p eth_rate=10 -p ib_count=0 -p ib_rate=0 -p ib='NO' -p opa_count=0 -p opa_rate=0 -p myri_count=0 -p myri_rate=0 -p myri='NO' -p memcore=8192 -p memcpu=65536 -p memnode=131072 -p gpu_count=4 -p exotic='NO' -p mic='NO' -p wattmeter='MULTIPLE' -p cluster_priority=201906 -p max_walltime=86400 -p production='YES' -p maintenance='NO' -p disk_reservation_count=3
      TXT

      expected_output2 = <<-TXT
oarnodesetting --sql "host='clusterb-1.fakesite.grid5000.fr' and type='default'" -p ip='172.16.64.1' -p cluster='clusterb' -p nodemodel='Dell PowerEdge T640' -p besteffort='YES' -p deploy='YES' -p virtual='ivt' -p cpuarch='x86_64' -p cpucore=8 -p cputype='Intel Xeon Silver 4110' -p cpufreq='2.1' -p disktype='SATA' -p chassis='Dell Inc. PowerEdge T640 FL1CBX2' -p eth_count=1 -p eth_rate=10 -p ib_count=0 -p ib_rate=0 -p ib='NO' -p opa_count=0 -p opa_rate=0 -p myri_count=0 -p myri_rate=0 -p myri='NO' -p memcore=8192 -p memcpu=65536 -p memnode=131072 -p gpu_count=4 -p exotic='NO' -p mic='NO' -p wattmeter='MULTIPLE' -p cluster_priority=201906 -p max_walltime=86400 -p production='YES' -p maintenance='NO' -p disk_reservation_count=3
      TXT

      expected_output3 = <<-TXT
echo '================================================================================'
echo; echo 'Adding disk sdb.clusterb-1 on host clusterb-1.fakesite.grid5000.fr:'
disk_exist 'clusterb-1.fakesite.grid5000.fr' 'sdb.clusterb-1' && echo '=> disk already exists'
disk_exist 'clusterb-1.fakesite.grid5000.fr' 'sdb.clusterb-1' || oarnodesetting -a -h '' -p host='clusterb-1.fakesite.grid5000.fr' -p type='disk' -p disk='sdb.clusterb-1'

echo; echo 'Setting properties for disk sdb.clusterb-1 on host clusterb-1.fakesite.grid5000.fr:'; echo
oarnodesetting --sql "host='clusterb-1.fakesite.grid5000.fr' and type='disk' and disk='sdb.clusterb-1'" -p cluster='clusterb' -p host='clusterb-1.fakesite.grid5000.fr' -p available_upto=0 -p deploy='YES' -p production='YES' -p maintenance='NO' -p disk='sdb.clusterb-1' -p diskpath='/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:1:0' -p cpuset=-1
      TXT

      expected_output4 = <<-TXT
oarnodesetting --sql "host='clusterb-2.fakesite.grid5000.fr' AND resource_id='33' AND type='default'" -p cpu=4 -p core=30 -p cpuset=13 -p gpu=8 -p gpu_model='GeForce RTX 2080 Ti' -p gpudevice=3 # This GPU is mapped on /dev/nvidia3
      TXT
      dont_expected_output5 = <<-TXT
echo; echo 'Adding disk sdb.clusterb-2 on host clusterb-1.fakesite.grid5000.fr:'
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_output)
      expect(generator_output[:stdout]).to include(expected_output2)
      expect(generator_output[:stdout]).to include(expected_output3)
      expect(generator_output[:stdout]).to include(expected_output4)
      expect(generator_output[:stdout]).not_to include(dont_expected_output5)
    end
  end

  context 'OAR server with data' do
    before do
      prepare_stubs("dump_oar_api_configured_server.json", "load_data_hierarchy_stubbed_data_bad_best_effort_property.json")
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
  clustera-2:
    ["~", "besteffort", "YES", "NO"]
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_clustera1_diff)
      expect(generator_output[:stdout]).to include(expected_clustera2_diff)
    end
  end

end
