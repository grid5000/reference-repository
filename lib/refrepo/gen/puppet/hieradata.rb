# frozen_string_literal: true

DATA = load_data_hierarchy.freeze

def generate_puppet_hieradata(options)
  output_dir = "#{options[:output_dir]}/platforms/production/hieradata/generated/locations".freeze
  FileUtils.mkdir_p(output_dir)
  options[:sites].each do |site|
    hash = DATA['sites'][site]
    hiera_file_path = "#{output_dir}/#{site}.yaml".freeze
    generate_location_file(site, hash, hiera_file_path)
  end
end

def generate_location_file(site, hash, hiera_file_path)
  hiera_site_location = {}

  supervision2_ip = hash['servers']['supervision2']['network_adapters']['default']['ip']

  # FIXME: This key should not be needed at all by Puppet code.
  #        Our puppet recipes should be able to deduce this value themselves instead
  #        of relying on an hardcoded hostname somewhere.
  hiera_site_location['puppet6::agent::server'] = "puppet6.#{site}.grid5000.fr".freeze

  hiera_site_location['munin::node::allow'] = [supervision2_ip]

  file_content = YAML.dump(hiera_site_location)
  output = File.open(hiera_file_path, 'w')
  output.write(file_content)
  output.close
end
