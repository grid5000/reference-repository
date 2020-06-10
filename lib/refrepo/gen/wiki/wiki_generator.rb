require "mediawiki_api"
require "diffy"

class WikiGenerator

  def initialize(page_name)
    @mw_client = MediawikiApi::Client.new(MW::API_URL)
    @page_name = page_name
  end

  def get_global_hash
    return G5K::get_global_hash
  end

  def login(_options)
    tries = 3
    begin
      conf = RefRepo::Utils.get_api_config
      @mw_client.log_in(conf['username'], conf['password'])
    rescue
      tries -= 1
      if tries > 0
        puts "Login failed. retrying..."
        sleep(1)
        retry
      else
        raise "Login failed and retries exhausted."
      end
    end
  end

  def generate_content
    raise "To be implemented in actual generators"
  end

  def remove_page_creation_date(content)
    return content.gsub(/''<small>Last generated from the Grid'5000 Reference API on .+<\/small>''/, '')
  end

  def generated_date_string
    commit = `git show --oneline -s`.split(' ').first
    date = Time.now.strftime("%Y-%m-%d")
    return "Last generated from the Grid'5000 Reference API on #{date} ([https://github.com/grid5000/reference-repository/commit/#{commit} commit #{commit}])"
  end

  #Actually edit the mediawiki page with the new generated content
  def update_page
    wiki_content = remove_page_creation_date(@mw_client.get_page_content(@page_name)).strip # .strip removes potential '\n' at end of file
    generated_content = remove_page_creation_date(@generated_content).strip
    if wiki_content == generated_content
      puts "No modification on #{@page_name}, skipping update"
    else
      @mw_client.edit({"title" => @page_name, "text" => @generated_content })
    end
  end

  #Get the given page content and print a diff if any
  #Return true if there are no differences, false otherwise
  def diff_page
    wiki_content = remove_page_creation_date(@mw_client.get_page_content(@page_name)).strip # .strip removes potential '\n' at end of file
    generated_content = remove_page_creation_date(@generated_content).strip
    diff = Diffy::Diff.new(wiki_content, generated_content, :context => 3)
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

  def update_files
    @files.each do |file|
      file_content = @mw_client.get_file_content(file['filename'])
      generated_content = File.read(file['path'])
      if file_content == generated_content
        puts "No modification on #{file['filename']}, skipping update"
      else
        @mw_client.update_file(file['filename'], file['path'], file['content_type'], file['comment'], true)
      end
    end
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

  #Execute actions on generator based on given options
  def exec(options)
    generate_content()

    ret = true
    #Login only if we need to
    if (options[:diff] || options[:update])
      login(options)
    end
    if (options[:diff])
      ret &= diff_page if instance_variable_get('@generated_content')
      ret &= diff_files if instance_variable_get('@files')
    end
    if (options[:print])
      print
    end
    if (options[:update])
      update_page if instance_variable_get('@generated_content')
      update_files if instance_variable_get('@files')
    end
    return ret
  end

end
