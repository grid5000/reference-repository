# coding: utf-8

class StatusGenerator < WikiGenerator

  def generate_content(_options)
    @global_hash = get_global_hash
    @site_uids = G5K::SITES
    @sites_number = @site_uids.length()

    @generated_content = "__NOEDITSECTION__\n"
    @generated_content += "{{Status|In production}}\n"
    @generated_content += "{{Portal|User}}\n"
    @generated_content += "{{Portal|Platform}}\n"
    @generated_content += "\n= [https://www.grid5000.fr/status/ Current platform events] (maintenance, outages, issues...) =\n"
    @generated_content += "If you experience problems, please check '''[https://www.grid5000.fr/status/ the platform's operation schedule]''' ''(Past, present and future incidents (planned or not...) are notified for all sites).''\n"
    @generated_content += MW::LINE_FEED
    @generated_content += MW::LINE_FEED
    @generated_content += "For other long running minor issue that may affect your experiment, you can check the list of known artifacts : '''[https://intranet.grid5000.fr/status/artifact/ Grid5000 Artifacts]''' ''(this list is also displayed when you connect on frontends).''\n"
    @generated_content += MW::LINE_FEED
    @generated_content += generate_resources_reservations
    @generated_content += MW::LINE_FEED
    @generated_content += generate_network_monitoring
    @generated_content += MW::LINE_FEED
    @generated_content += generate_node_monitoring
    @generated_content += MW::LINE_FEED
    @generated_content += generate_usage_statistics
    @generated_content += MW::LINE_FEED
    @generated_content += generate_jenkins
    @generated_content += MW.italic(MW.small(generated_date_string))
    @generated_content += MW::LINE_FEED
  end

  def generate_resources_reservations
    data = "= Resources reservations (OAR) status =\n"
    data += MW::LINE_FEED
    data += "{|\n"
    data += "|bgcolor=\"#aaaaaa\" colspan=\"#{@sites_number}\"|\n"
    data += "'''Drawgantt''' ''(past, current and future OAR jobs scheduling)''\n"
    data += "|-\n"
    data += "|bgcolor=\"#eeeeee\" colspan=\"#{@sites_number}\"|\n"
    data += "Default view:\n"
    data += "|-\n"

    # Loop over Grid'5000 sites for Drawgantt's links
    @site_uids.sort.each do |site_uid|
      data += "|bgcolor=\"#ffffff\" valign=\"top\" style=\"border:1px solid #cccccc;padding:1em;padding-top:0.5em;\"|\n"
      data += "<big>'''#{site_uid.capitalize}'''</big><br>\n"
      data += "[https://intranet.grid5000.fr/oar/#{site_uid.capitalize}/drawgantt-svg/ '''nodes''']<br>\n"
      if has_queue_production?(site_uid)
        data += "[https://intranet.grid5000.fr/oar/#{site_uid.capitalize}/drawgantt-svg-prod/ '''nodes (production)''']<br>\n"
      end
      if has_reservable_disks?(site_uid)
        data += "[https://intranet.grid5000.fr/oar/#{site_uid.capitalize}/drawgantt-svg-disks/ disks]<br>\n"
      end
      data += "[https://intranet.grid5000.fr/oar/#{site_uid.capitalize}/drawgantt-svg-subnets/ subnets]<br>\n"
      data += "[https://intranet.grid5000.fr/oar/#{site_uid.capitalize}/drawgantt-svg-vlans/ vlans]\n"
    end

    data += "|-\n"
    data += "|bgcolor=\"#eeeeee\" colspan=\"#{@sites_number}\"|\n"
    data += "Forecast view for 1 week:\n"
    data += "|-\n"

    # Loop over Grid'5000 sites for Drawgantt's weekly links
    @site_uids.sort.each do |site_uid|
      data += "|bgcolor=\"#ffffff\" valign=\"top\" style=\"border:1px solid #cccccc;padding:1em;padding-top:0.5em;\"|\n"
      data += "<big>'''#{site_uid.capitalize}'''</big><br>\n"
      data += "[https://intranet.grid5000.fr/oar/#{site_uid.capitalize}/drawgantt-svg/?relative_start=-28800&relative_stop=604800 '''nodes''']<br>\n"
      if has_queue_production?(site_uid)
        data += "[https://intranet.grid5000.fr/oar/#{site_uid.capitalize}/drawgantt-svg-prod/?relative_start=-28800&relative_stop=604800 '''nodes (production)''']<br>\n"
      end
      if has_reservable_disks?(site_uid)
        data += "[https://intranet.grid5000.fr/oar/#{site_uid.capitalize}/drawgantt-svg-disks/?relative_start=-28800&relative_stop=604800 disks]<br>\n"
      end
      data += "[https://intranet.grid5000.fr/oar/#{site_uid.capitalize}/drawgantt-svg-subnets/?relative_start=-28800&relative_stop=604800 subnets]<br>\n"
      data += "[https://intranet.grid5000.fr/oar/#{site_uid.capitalize}/drawgantt-svg-vlans/?relative_start=-28800&relative_stop=604800 vlans]\n"
    end

    data += "|-\n"
    data += "|bgcolor=\"#aaaaaa\" colspan=\"#{@sites_number}\"|\n"
    data += "'''Monika''' ''(current placement and queued jobs status)''\n"
    data += "|-\n"

    # Loop over Grid'5000 sites for Monika's links
    @site_uids.sort.each do |site_uid|
      if has_queue_production?(site_uid)
        data += "|bgcolor=\"#ffffff\" valign=\"top\" style=\"border:1px solid #cccccc;padding:1em;padding-top:0.5em;\"|\n"
        data += "[https://intranet.grid5000.fr/oar/#{site_uid.capitalize}/monika.cgi '''#{site_uid.capitalize}''']<br>\n"
        data += "[https://intranet.grid5000.fr/oar/#{site_uid.capitalize}/monika-prod.cgi '''#{site_uid.capitalize} (production)''']\n"
      else
        data += "|bgcolor=\"#ffffff\" valign=\"top\" style=\"border:1px solid #cccccc;padding:1em;padding-top:0.5em;\"|\n"
        data += "[https://intranet.grid5000.fr/oar/#{site_uid.capitalize}/monika.cgi '''#{site_uid.capitalize}''']\n"
      end
    end

    data += "|}\n"
  end

  def generate_network_monitoring
    data = "= Network Monitoring =\n"
    data += "== Backbone network status and load ==\n"
    data += "[https://www.renater.fr/documentation/ressources-multimedia/weathermap/g5k/ Grid'5000 Weathermap]  (courtesy of Renater)\n"
    data += MW::LINE_FEED
    data += "Shows the actual state of the opticals links between the Grid'5000 10Gb-ready sites. A link painted in black on the weathermap means that you won't be able to access this site nodes from the Grid'5000 internal network.\n"
    data
  end

  def generate_node_monitoring
    data = "= Node Monitoring =\n"
    data += MW::LINE_FEED
    data += "{|\n"
    @site_uids.sort.each do |site_uid|
        data += "|bgcolor=\"#ffffff\" valign=\"top\" style=\"border:1px solid #cccccc;padding:1em;padding-top:0.5em;\"|\n"
        data += "[https://api.grid5000.fr/stable/sites/#{site_uid}/metrics/dashboard '''#{site_uid.capitalize}''']\n"
    end
    data += "|}\n\n"
  end

  def generate_usage_statistics
    data = "= Usage statistics =\n"
    data + "[https://intranet.grid5000.fr/stats/ Stats5k] gathers a lot of statistics about the testbed.\n"
  end

  def generate_jenkins
    data = "= Jenkins =\n"
    data += "[https://intranet.grid5000.fr/jenkins-status/ Jenkins] tests most of Grid'5000 services. The web interface provides a summary of results, indicating platform health. Detailed logs are not normally available to users, but access can be requested if needed.\n"
    data += MW::LINE_FEED
    data += "{|\n"

    @site_uids.sort.each do |site_uid|
      data += "|bgcolor=\"#ffffff\" valign=\"top\" style=\"border:1px solid #cccccc;padding:1em;padding-top:0.5em;\"|\n"
      data += "[https://intranet.grid5000.fr/jenkins-status/?site=#{site_uid} '''#{site_uid.capitalize}''']\n"
    end

    data += "|}\n"
  end

  def has_reservable_disks?(site)
    site_hash = @global_hash["sites"][site]
    site_hash.fetch("clusters", {}).each_value do |cluster_hash|
      cluster_hash.fetch('nodes').each_value do |node_hash|
        sd = node_hash['storage_devices']
        reservable_disks = sd.select{ |v| v['reservation'] == true }.count > 0

        if reservable_disks
          return true
        end
      end
    end

    false
  end

  def has_queue_production?(site)
    site_hash = @global_hash["sites"][site]
    site_hash.fetch("clusters", {}).each_value do |cluster_hash|
      if cluster_hash["queues"].include?("abaca") || cluster_hash["queues"].include?("production")
        return true
      end
    end

    false
  end
end
