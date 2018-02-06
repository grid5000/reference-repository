
require "optparse"
require "mediawiki_api"
require "diffy"

require_relative "./mw_utils"

class WikiGenerator

  def initialize(page_name)
    @mw_client = MediawikiApi::Client.new(MW::API_URL)
    @page_name = page_name
  end

  def login(options)
    if (options[:user] && options[:pwd])
      @mw_client.log_in(options[:user], options[:pwd])
    end
  end

  def generate_content
    raise "To be implemented in actual generators"
  end

  #Actually edit the mediawiki page with the new generated content
  def update_page
    @mw_client.edit({"title" => @page_name, "text" => @generated_content })
  end

  #Get the given page content and print a diff if any
  #Return true if there are differences, false otherwise
  def diff_page()
    wiki_content = @mw_client.get_page_content(@page_name)
    diff = Diffy::Diff.new(wiki_content, @generated_content, :context => 0)
    if (diff.to_s.empty?)
      return false
    end
    puts "Differences between generated and current wiki content for page #{@page_name}:\n#{diff.to_s(:color)}"
  end

  #print generator content to stdout
  def print()
    puts @generated_content
  end

  #Generic static method for cli arguments parsing
  def self.parse_options
    conf = ENV['HOME']+'/.grid5000_api.yml'
    yconf = YAML::load(IO::read(conf)) rescue {}
    api_user = yconf['username']
    api_password = yconf['password']

    options = {
      :diff => false,
      :print => false,
      :update => false,
      :user => ENV['API_USER'] || api_user,
      :pwd => ENV['API_PASSWORD'] || api_password
    }

    opt_parse = OptionParser.new do |opts|
      opts.banner = "Usage: <wiki_generator>.rb\n"
      opts.banner += "This script looks for file ~/.grid5000_api.yml containing your API username and password credentials. The script also recognize API_USER and API_PASSWORD environment variables."

      opts.on('-d', '--diff', 'Print a diff of the current wiki page against the content to generated') do
        options[:diff] = true
      end

      opts.on('-u', '--update', 'Update the wiki page with the new generated content') do
        options[:update] = true
      end

      opts.on('-o', '--print', 'Print the new generated content on stdout') do
        options[:print] = true
      end

      # Print an options summary.
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end
    opt_parse.parse!
    if (!options[:diff] && !options[:print] && !options[:update])
      puts "At least one action must be given!\n#{opt_parse.to_s}"
      return false
    end
    return options
  end

  #Execute actions on generator based on given options
  def self.exec(generator, options)
    generator.generate_content()

    #Login only if we need to
    if (options[:diff] || options[:update])
      generator.login(options)
    end
    if (options[:diff])
      generator.diff_page
    end
    if (options[:print])
      generator.print
    end
    if (options[:update])
      generator.update_page
    end
  end

end
