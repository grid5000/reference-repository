$LOAD_PATH.unshift(__dir__)
require 'spec_helper'

conf = RefRepo::Utils.get_api_config

describe 'OarProperties' do
  context 'testing arguments' do
    before do
      prepare_stubs('dump_oar_api_empty_server.json', 'load_data_hierarchy_stubbed_data.json')
    end

    it 'should accept case where only the site is specified' do
      uri = URI(conf['uri'])

      response = Net::HTTP.get(uri)

      expect(response).to be_an_instance_of(String)

      options = {
        table: true,
        print: false,
        update: false,
        diff: false,
        sites: ['fakesite']
      }

      expected_header = <<~TXT
        +-------------+----------------------+-------+-------+--------+---------------------------+------+------------+--------------------------------+
        | cluster     | host                 | cpu   | core  | cpuset | cpumodel                  | gpu  | gpudevice  | gpumodel                       |
        +-------------+----------------------+-------+-------+--------+---------------------------+------+------------+--------------------------------+
      TXT

      generator_output = capture do
        generate_oar_properties(options)
      end

      expect(generator_output[:stdout]).to include(expected_header)
    end

    it 'should should accept case where only the site is specified' do
      uri = URI(conf['uri'])

      response = Net::HTTP.get(uri)

      expect(response).to be_an_instance_of(String)

      options = {
        table: true,
        print: false,
        update: false,
        diff: false,
        sites: ['fakesite2']
      }

      expect do
        generate_oar_properties(options)
      end.to raise_error("The provided site does not exist : I can't detect clusters")
    end
  end
end
