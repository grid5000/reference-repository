# coding: utf-8
require 'refrepo/gen/wiki/wiki_generator'
require 'refrepo/valid/network'

# This class generates the network description of each site, in .dot
# and .png format
class SiteNetworkGenerator < WikiGenerator

  def initialize(page_name, site)
    super(page_name)
    @site = site
    name = "#{@site.capitalize}Network"
    @files = [
      {	'content-type' => 'text/plain',
        'filename' => "#{name}.dot",
        'path' => "./#{name}.dot",
        'comment' => "#{site.capitalize} network description" },
      { 'content-type' => 'image/png',
        'filename' => "#{name}.png",
        'path' => "./#{name}.png",
        'comment' => "#{site.capitalize} network description" }
    ]
  end

  def generate_equipments
    h = G5K::get_global_hash['sites'][@site]
    return h['networks'].to_a.map { |e| "* #{e[0]}: #{e[1]['model']}" }.sort.join("\n")
  end

  def generate_content
    @generated_content = "__NOTOC__\n__NOEDITSECTION__\n"
    @generated_content += "= Network devices models =\n"
    @generated_content += generate_equipments + "\n"
    @generated_content += "More details (including address ranges are available from the [[Grid5000:Network]] page.\n"
    @generated_content += MW::LINE_FEED

    # this will generate dot and png network maps in the current directory
    check_network_description({:sites => [@site], :dot => true})
  end
end

if __FILE__ == $0
  options = WikiGenerator::parse_options

  if (options)
    ret = 2
    begin
      ret = true
      generators = options[:sites].map{ |site| SiteNetworkGenerator.new('Generated/' + site.capitalize + 'Network', site) }
      generators.each{ |generator|
        ret &= generator.exec(options)
      }
    rescue MediawikiApi::ApiError => e
      puts e, e.backtrace
      ret = 3
    rescue StandardError => e
      puts e, e.backtrace
      ret = 4
    ensure
      exit(ret)
    end
  end
end
