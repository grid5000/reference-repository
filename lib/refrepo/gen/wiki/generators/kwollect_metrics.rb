# coding: utf-8

class KwollectMetricsGenerator < WikiGenerator

  

  def generate_content(_options)
    @generated_content = "__NOEDITSECTION__\n"
    @generated_content = "\nMetrics marked with * must be activated on demand, and metrics marked with ** are activated on non-deploy jobs by default.\n\n"
    @generated_content += "{|class=\"wikitable\"\n"
    @generated_content += "! style=\"width: 15%\" | Metric Name\n"
    @generated_content += "! style=\"width: 30%\" | Description\n"
    @generated_content += "! style=\"width: 55%\" | Available on\n"
    @generated_content += "|-\n"

    sites = get_global_hash()["sites"]

    all_metrics = sites.each_value.map{|s| s["clusters"].each_value.map{|c| c.fetch('metrics', [])}}.flatten
    all_metrics += sites.each_value.map{|s| s["network_equipments"].each_value.map{|c| c.fetch('metrics', [])}}.flatten
    all_metrics += sites.each_value.map{|s| s.fetch("pdus", {}).each_value.map{|c| c.fetch('metrics', [])}}.flatten

    metric_names = all_metrics.map{|metric| metric["name"]}.uniq

    metric_names.sort.each do |metric_name|

      optional = all_metrics.select{|m| m["name"] == metric_name}.any?{|metric| metric["period"] == 0} ? "*" : ""
      descriptions = all_metrics.select{|m| m["name"] == metric_name}.map{|metric| metric["description"]}.uniq
      if descriptions.length != 1
        description = longest_common_prefix(descriptions) + "XXX" + longest_common_suffix(descriptions)
      else
        description = descriptions.first
      end
      if metric_name =~ /prom_.*default_metrics/
        prom_metric_ids = all_metrics.select{|m| m["name"] == metric_name}.map{|metric| metric["source"]["id"]}.first
        description += ":<br/>''#{prom_metric_ids.join(", ")}''"
        optional = "**"
      end
      @generated_content += "|-\n|#{metric_name}#{optional}\n|#{description}\n|"

      sites.each_value.sort_by{|s| s['uid']}.each do |site|
        devices = site["clusters"].each_value.select{|c| c.fetch('metrics', []).map{|m| m["name"]}.any?{|m| m == metric_name}}.map{|c| c["uid"]}.sort
        devices += site["network_equipments"].each_value.select{|c| c.fetch('metrics', []).map{|m| m["name"]}.any?{|m| m == metric_name}}.map{|c| "''#{c['uid']}''"}.sort
        devices += site.fetch('pdus', {}).each_value.select{|c| c.fetch('metrics', []).map{|m| m["name"]}.any?{|m| m == metric_name}}.map{|c| "''#{c['uid']}''"}.sort
        if not devices.empty?
          @generated_content += "'''#{site['uid']}''':"
          @generated_content += " #{devices.join(', ')}"
          @generated_content += "<br/>"
        end
      end
      #@generated_content += "\n<!-- #{descriptions} -->"
      @generated_content += "\n"
    end

    @generated_content += "|}\n"

  end

  def longest_common_prefix(strs)
    return '' if strs.empty?
    min, max = strs.minmax
    idx = min.size.times{ |i| break i if min[i] != max[i] }
    min[0...idx]
  end
  def longest_common_suffix(strs)
    return longest_common_prefix(strs.map{|s| s.reverse}).reverse
  end
end
