module RefRepo::Utils
  def self.get_api_config
    conf = ENV['HOME']+'/.grid5000_api.yml'
    yconf = YAML::load(IO::read(conf)) rescue {}
    yconf['uri'] ||= 'https://api.grid5000.fr/'
    yconf['version'] ||= 'stable'
    return yconf
  end

  def self.get_api(path)
    conf = get_api_config
    if conf['username'] and conf['password']
      o = { :http_basic_authentication => [conf['username'], conf['password']] }
    else
      o = {}
    end
    d = open("#{conf['uri']}/#{conf['version']}/#{path}", o).read
    return JSON::parse(d)
  end

  def self.get_sites
    return (Dir::entries('input/grid5000/sites') - ['.', '..']).sort
  end
end

# Various monkey patches
class Hash
  def slice(*extract)
    h2 = self.select{|key, value| extract.include?(key) }
    h2
  end
end
