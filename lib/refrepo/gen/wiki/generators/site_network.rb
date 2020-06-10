# coding: utf-8
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
    return h['network_equipments'].to_a.map { |e| "* #{e[0]}: #{e[1]['model']}" }.sort.join("\n")
  end

  def generate_content
    @generated_content = "__NOTOC__\n__NOEDITSECTION__\n"
    @generated_content += "= Network devices models =\n"
    @generated_content += generate_equipments + "\n"
    @generated_content += "More details (including address ranges are available from the [[Grid5000:Network]] page.\n"
    @generated_content += MW::LINE_FEED

    # this will generate dot and png network maps in the current directory
    puts "WARNING : Graph generation depends on graphviz version, check the graphs before uploading it. graphviz 2.40.1-6 seems to work correctly"
    check_network_description({:sites => [@site], :dot => true})
  end
end
