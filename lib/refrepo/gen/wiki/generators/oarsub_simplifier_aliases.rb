# coding: utf-8

require 'refrepo/gen/puppet/oarsub-simplifier-aliases'

class OarsubSimplifierAliasesGenerator < WikiGenerator
  

  def generate_content(options)
    default_aliases = get_sub_simplifier_default_aliases(options)
    sites_aliases = generate_all_sites_aliases

    default_aliases_by_category = {}
    default_aliases.each do |al, data|
      default_aliases_by_category[data['category']] ||= {}
      default_aliases_by_category[data['category']][al] = data
    end

    @generated_content = "__NOEDITSECTION__\n"

    @generated_content += "=== Clusters and nodes ===\n"
    @generated_content += "<code>%d</code> is a digit representing a node's number.<br/><br/>\n"

    sites_aliases.each do |site, aliases|
      @generated_content += "{|class=\"wikitable mw-collapsible mw-collapsed\"\n"
      @generated_content += "|+ style=white-space:nowrap | #{site.capitalize}\n"
      @generated_content += "! style=\"width: 15%\" | Alias\n"
      @generated_content += "! style=\"width: 30%\" | Description\n"
      @generated_content += "! style=\"width: 30%\" | Translate to\n"
      aliases.each do |al, value|
        desc = if al.match(/([a-zA-Z]+)-\%d/)
                 "Select a node from cluster #{$1.capitalize}"
               else
                 "Select node(s) from cluster #{al.capitalize}"
               end

        @generated_content += "|-\n"
        @generated_content += "|''#{al}''\n"
        @generated_content += "|#{desc}\n"
        @generated_content += "|<code>#{value}</code>\n"
      end
      @generated_content += "|}\n"
      @generated_content += "\n"
    end

    default_aliases_by_category.sort.each do |cat, data|
      @generated_content += "=== #{cat} ===\n"
      @generated_content += "{|class=\"wikitable\"\n"
      @generated_content += "! style=\"width: 15%\" | Alias\n"
      @generated_content += "! style=\"width: 30%\" | Description\n"
      @generated_content += "! style=\"width: 30%\" | Translate to\n"

      data.each do |al, c|
        @generated_content += "|-\n"
        @generated_content += "|''#{al}''\n"
        @generated_content += "|#{c['desc']}\n"
        @generated_content += "|<code>#{c['value']}</code>\n"
      end

      @generated_content += "|}\n"
      @generated_content += "\n"
    end
  end
end
