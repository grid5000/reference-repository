require 'json'

Dir::glob('data*.json').each do |f|
  puts f
  d = JSON::load(IO::read(f))
  File::open(f, 'w') do |fd|
    fd.puts JSON::pretty_generate(d)
  end
end

Dir::glob('data*.json').each do |f|
  puts f
  d = JSON::load(IO::read(f))
  d.each_pair do |k1, v1|
    next if k1 != 'sites'
    v1.each_pair do |_k2, v2|
      v2.each_pair do |k3, v3|
        next if k3 != 'clusters'
        v3.each_pair do |_clusteruid, v4|
          v4.each_pair do |k5, v5|
            next if k5 != 'nodes'
            v5.each_pair do |_nodeuid, v6|
              (v6['gpu_devices'] || {}).each_pair do |_k7, v7|
                if not v7.has_key?('compute_capability')
                  v7['compute_capability'] = '7.9'
                end
              end
            end
          end
        end
      end
    end
  end
  File::open(f, 'w') do |fd|
    fd.puts JSON::pretty_generate(d)
  end
end
