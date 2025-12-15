module RefRepo::Utils
  def self.get_api_config
    conf = ENV['HOME'] + '/.grid5000_api.yml'
    yconf = begin
      YAML.load(IO.read(conf))
    rescue StandardError
      {}
    end
    yconf['uri'] ||= 'https://api.grid5000.fr/'
    yconf['version'] ||= 'stable'
    yconf
  end

  def self.get_api(path)
    conf = get_api_config
    if conf['username'] and conf['password']
      o = { http_basic_authentication: [conf['username'], conf['password']] }
    else
      o = {}
      puts 'Check the documentation https://www.grid5000.fr/w/TechTeam:Reference_Repository#Credentials and your ~/.grid5000_api.yml file'
    end
    d = URI.open("#{conf['uri']}/#{conf['version']}/#{path}", o).read
    JSON.parse(d)
  end

  def self.get_public_api(path, version = 'stable')
    d = URI.open("https://public-api.grid5000.fr/#{version}/#{path}").read
    JSON.parse(d)
  end

  def self.get_sites
    (Dir.entries('input/grid5000/sites') - ['.', '..']).sort
  end

  IGNORE_ERROR_MESSAGE = 'Aborting generation. You can ignore this error and '\
                         'proceed with generation by setting the '\
                         'IGNORE_PARTIAL_SITE environment variable.'.freeze

  def self.warn_or_abort_partial_site(message)
    raise([message, IGNORE_ERROR_MESSAGE].join("\n")) unless ENV.has_key?('IGNORE_PARTIAL_SITE')

    warn message
  end

  def self.get_as_gb(quantity)
    (quantity.to_f / 2**30).round(0)
  end
end

def split_cluster_node(k)
  [k[/([a-z]+)/, 1], k[/[a-z](\d+)/, 1].to_i, k[/-(\d+)/, 1].to_i]
end
