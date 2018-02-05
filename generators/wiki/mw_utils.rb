require 'pp'
require 'open-uri'
require 'uri'
require 'net/http'
require 'net/https'
require 'mediawiki_api'

require_relative "../lib/input_loader"

#Adding method to mediawiki_api client
module MediawikiApi

  class Client

    def get_page_content(page_name)
      get_conn = Faraday.new(url: MW::BASE_URL + "index.php/#{page_name}") do |faraday|
        faraday.request :multipart
        faraday.request :url_encoded
        faraday.use :cookie_jar, jar: @cookies
        faraday.use FaradayMiddleware::FollowRedirects
        faraday.adapter Faraday.default_adapter
      end
      params = {
        :token_type => false,
        :action => 'raw'
      }
      params[:token] = get_token(:csrf)
      res = get_conn.send(:get, '', params)
      res.body
    end

    def update_file(filename, path, content_type, comment, ignorewarnings, text = nil)
      file = Faraday::UploadIO.new(path, content_type)
      action(:upload,
             filename: filename, file: file, comment: comment, text: text,
             ignorewarnings: ignorewarnings)
    end
  end

end

#Defines global Grid5000 helpers (TODO move to its own file once it is big enough)
module G5K

  SITES = load_yaml_file_hierarchy(File.expand_path("../../input/grid5000/", File.dirname(__FILE__)))['sites'].keys.sort
  
  # This method compacts an array of integers as follows
  # nodeset([2,3,4,7,9,10,12]) returns the string '[2-4,<wbr>7,<wbr>9-10,<wbr>12]'
  # where <wbr> is a hidden tag that enables carriage return in wikimedia
  def self.nodeset(a)
    l = a.length
    return '' if l == 0
    a = a.compact.uniq.sort
    a0 = a[0]
    s = "[#{a0}"
    i = 1
    while i < l
      fast_forward = (i < l and a[i] - a0 == 1) ? true : false
      (a0 = a[i] and i+=1 ) while (i < l and a[i] - a0 == 1) # fast forward
      if fast_forward
        s += (i != l) ? "-#{a0},<wbr>#{a[i]}" : "-#{a0}"
      else
        s += ",<wbr>#{a[i]}"
      end
      a0 = a[i]
      i += 1
    end
    s += ']'
  end

  def self.get_size(x)
    gbytes = (x.to_f / 2**30).floor
    if gbytes < 2**10
      gbytes.to_s + '&nbsp;GB'
    else
      (x.to_f / 2**40).round(3).to_s + '&nbsp;TB'
    end
  end
  
  def self.get_rate(x)
    return '' if (x == 0 || x.nil?)
    mbps = (x.to_f / 10**6).floor
    if mbps < 1000
      mbps.to_s + '&nbsp;Mbps'
    else
      (x.to_f / 10**9).floor.to_s + '&nbsp;Gbps'
    end
  end

  def self.pluralize(count, word)
    return (count == 1 || word[-1] == 's') ? word : word + 's'
  end
  
end

#Defines MediaWiki helpers
module MW

  BASE_URL = "https://www.grid5000.fr/mediawiki/"

  API_URL = BASE_URL + "api.php"

  TABLE_START = "{|"

  TABLE_END = "|}"

  TABLE_ROW = "|-"

  TABLE_HEADER = "!"

  INLINE_CELL = "||"

  TABLE_CELL = "|"

  UNSORTED_INLINE_CELL = "!!"

  UNSORTED_TABLE_CELL = "!"
  
  LINE_FEED = "\n"

  LIST_ITEM = "*"

  NUMBERED_LIST_ITEM = "#"

  HTML_LINE_FEED = "<br />"

  def self.generate_table(table_options, columns, rows)
    table_text = MW::TABLE_START + table_options

    table_text += MW::LINE_FEED + MW::TABLE_ROW + MW::LINE_FEED

    columns.each { |col|
      if col.kind_of?(Hash)
        table_text += MW::TABLE_HEADER + col[:attributes] + MW::TABLE_CELL + col[:text] + MW::LINE_FEED
      else
        table_text += MW::TABLE_HEADER + MW::TABLE_CELL + col + MW::LINE_FEED
      end
    }

    rows.each { |row|
      if row.kind_of?(Hash) and row[:sort] == false
        row = row[:columns]
        table_cell = MW::UNSORTED_TABLE_CELL
        inline_cell = MW::UNSORTED_INLINE_CELL
      else
        table_cell = MW::TABLE_CELL
        inline_cell = MW::INLINE_CELL
      end
      table_text += MW::TABLE_ROW + MW::LINE_FEED
      row.each_with_index{ |cell, i|
        if (i == 0)
          table_text += table_cell
        else
          table_text += inline_cell
        end
        table_text += cell.to_s
      }
      table_text += MW::LINE_FEED
    }
    table_text += MW::LINE_FEED + MW::TABLE_END
    return table_text
  end

  def self.generate_hash_table(hash)
    format = " valign=\"top\" style=\"background-color: #f9f9f9; padding: 0px 10px 0px 3px;\" "
    table = [MW::TABLE_START, MW::TABLE_ROW]
    hash.each { |k, v|
      table << MW::TABLE_CELL + format + MW::TABLE_CELL + "'''#{k}:'''"
      table << MW::TABLE_CELL + " #{v}<br/>"
      table << MW::TABLE_ROW
    }
    (table << MW::TABLE_END).join(MW::LINE_FEED)
  end

  def self.small(text)
    "<small>" + text + "</small>"
  end

  def self.big(text)
    "<big>" + text + "</big>"
  end

  def self.italic(text)
    "''" + text + "''"
  end
 
  def self.bold(text)
    "'''" + text + "'''"
  end

  def self.heading(text, level = 1)
    "#{'=' * level} " + text + " #{'=' * level}"
  end

  def self.code(text)
    "<code>" + text + "</code>"
  end   

end
pp G5K::SITES
