
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
    options = {
      :diff => false,
      :print => false,
      :update => false
    }

    opt_parse = OptionParser.new do |opts|
      opts.banner = "Usage: <wiki_generator>.rb --api-user user --api-password password"

      opts.on('-u=user', '--api-user=user', String, 'User for HTTP authentication ') do |user|
        options[:user] = user
      end

      opts.on('-p=pwd', '--api-password=pwd', String, 'Password for HTTP authentication') do |pwd|
        options[:pwd] = pwd
      end

      opts.on('-d', '--diff', 'Print a diff of the current wiki page against the content to generated') do
        options[:diff] = true
      end

      opts.on('-u', '--update', 'Update the wiki page with the new generated content') do
        options[:update] = true
      end

      opts.on('-p', '--print', 'Print the new generated content on stdout') do
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
    generator.login(options)
    generator.generate_content()

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
