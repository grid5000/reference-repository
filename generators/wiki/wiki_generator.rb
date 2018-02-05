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
  #Return true if there are no differences, false otherwise
  def diff_page()
    wiki_content = remove_page_creation_date(@mw_client.get_page_content(@page_name)).strip # .strip removes potential '\n' at end of file
    generated_content = remove_page_creation_date(@generated_content).strip
    diff = Diffy::Diff.new(wiki_content, generated_content, :context => 0)
    if (diff.to_s.empty?)
      puts "No differences found between generated and current wiki content for page #{@page_name}."
      return true
    end
    puts "Differences between generated and current wiki content for page #{@page_name}:"
    puts '------------ PAGE DIFF BEGIN ------------'
    puts "#{diff.to_s(:text)}"
    puts '------------- PAGE DIFF END -------------'
    return false
  end

  def remove_page_creation_date(content)
    return content.gsub(/''<small>Generated from the Grid5000 APIs on .+<\/small>''/, '')
  end

  def update_files
    @files.each { |file|
      @mw_client.update_file(file['filename'], file['path'], file['content_type'], file['comment'], true)
    }
  end

  def diff_files
    ret = true
    @files.each { |file|
      if file['content-type'] == 'text/plain'
        file_content = @mw_client.get_file_content(file['filename'])
        generated_content = File.read(file['path'])
        diff = Diffy::Diff.new(file_content, generated_content, :context => 0)
        if (diff.to_s.empty?)
          puts "No differences found between generated and current content for file #{file['filename']}."
          ret &= true
        else
          puts "Differences between generated and current content for file #{file['filename']}:"
          puts '------------ FILE DIFF BEGIN ------------'
          puts "#{diff.to_s(:text)}"
          puts '------------- FILE DIFF END -------------'
          ret &= false
        end
      end
    }
    return ret
  end
    
  #print generator content to stdout
  def print()
    puts '---------- GENERATED PAGE BEGIN ----------'
    puts @generated_content
    puts '----------- GENERATED PAGE END -----------'
  end

  #Generic static method for cli arguments parsing
  def self.parse_options
    conf = ENV['HOME']+'/.grid5000_api.yml'
    yconf = YAML::load(IO::read(conf)) rescue {}
    api_user = yconf['username']
    api_password = yconf['password']

    options = {
      :sites => G5K::SITES,
      :diff => false,
      :print => false,
      :update => false,
      :user => ENV['API_USER'] || api_user,
      :pwd => ENV['API_PASSWORD'] || api_password
    }

    opt_parse = OptionParser.new do |opts|
      opts.banner = "Usage: <wiki_generator>.rb\n"
      opts.banner += "This script looks for file ~/.grid5000_api.yml containing your API username and password credentials. The script also recognize API_USER and API_PASSWORD environment variables."

      opts.on('-s', '--sites=site1,site2', Array, 'Only consider these sites (when applicable)') do |sites|
        options[:sites] = sites.map{ |e| e.downcase }
      end
      
      opts.on('-d', '--diff', 'Print a diff of the current wiki page against the content to generate') do
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

    ret = true
    #Login only if we need to
    if (options[:diff] || options[:update])
      generator.login(options)
    end
    if (options[:diff])
      ret &= generator.diff_page if generator.instance_variable_get('@generated_content')
      ret &= generator.diff_files if generator.instance_variable_get('@files')
    end
    if (options[:print])
      generator.print
    end
    if (options[:update])
      generator.update_page if generator.instance_variable_get('@generated_content')
      generator.update_files if generator.instance_variable_get('@files')
    end
    return ret
  end

end
