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
      puts "Check the documentation https://www.grid5000.fr/w/TechTeam:Reference_Repository#Credentials and your ~/.grid5000_api.yml file"
    end
    d = URI.open("#{conf['uri']}/#{conf['version']}/#{path}", o).read
    return JSON::parse(d)
  end

  def self.get_public_api(path, version='stable')
    d = URI.open("https://public-api.grid5000.fr/#{version}/#{path}").read
    return JSON::parse(d)
  end

  def self.get_sites
    return (Dir::entries('input/grid5000/sites') - ['.', '..']).sort
  end

  IGNORE_ERROR_MESSAGE = "Aborting generation. You can ignore this error and "\
                         "proceed with generation by setting the "\
                         "IGNORE_PARTIAL_SITE environment variable.".freeze

  def self.warn_or_abort_partial_site(message)
    if ENV.has_key?('IGNORE_PARTIAL_SITE')
      STDERR.puts message
    else
      raise([message, IGNORE_ERROR_MESSAGE].join("\n"))
    end
  end

  def self.get_as_gb(quantity)
    (quantity.to_f/2**30).round(0)
  end
end

# Various monkey patches
class Hash
  def slice(*extract)
    h2 = self.select{|key, _value| extract.include?(key) }
    h2
  end
end
