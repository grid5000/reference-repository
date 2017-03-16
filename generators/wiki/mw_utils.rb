
#Defines MediaWiki helpers

module MW

  BASE_URL = "https://www.grid5000.fr/mediawiki/api.php"

  TABLE_START = "{|"

  TABLE_END = "|}"

  TABLE_ROW = "|-"

  TABLE_HEADER = "!"

  INLINE_CELL = "||"

  TABLE_CELL = "|"

  LINE_FEED = "\n"

  HTML_LINE_FEED = "<br />"

  def self.generate_table(table_options, columns, rows)
    table_text = MW::TABLE_START + table_options

    table_text += MW::LINE_FEED + MW::TABLE_ROW + MW::LINE_FEED

    columns.each { |col|
      table_text += MW::TABLE_HEADER + MW::TABLE_CELL + col + MW::LINE_FEED
    }

    rows.each { |row|
      table_text += MW::TABLE_ROW + MW::LINE_FEED
      row.each_with_index{ |cell, i|
        if (i == 0)
          table_text += MW::TABLE_CELL
        else
          table_text += MW::INLINE_CELL
        end
        table_text += cell.to_s
      }
      table_text += MW::LINE_FEED
    }
    table_text += MW::LINE_FEED + MW::TABLE_END
    return table_text
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

end
