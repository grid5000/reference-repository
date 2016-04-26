#
# All of the following is just to check the value of node['monitoring']['wattmeter']...
#

def measurement_point_name(measure_point, site)
  port = measure_point['port'] || measure_point['measure'] || 0
  measure_point_name = "#{port}.#{measure_point['uid']}.#{site['uid']}.grid5000.fr"
  measure_point_name
end

def count_measurement_points(pdu_info, site_pdu_outlets, site)
  pdu_info.each do |measure_point|
    measure_point_name = measurement_point_name(measure_point, site)
    site_pdu_outlets[measure_point_name] = 0 unless site_pdu_outlets.has_key?(measure_point_name)
    site_pdu_outlets[measure_point_name] += 1
  end
end

# compute the annotation for the ["monitoring"]["wattmeter"] section from
# A pdu_info array representing all the pdus to take into account for a view of power consumption
# A site_pdus array with information about whether a given pdu has per_outlets measurements
# a site_pdu_outlets array with information about the number of nodes connected ot a given pdu outlet
def monitoring_wattmeter_annotation(pdu_info, site_pdus, site_pdu_outlets, site)
  per_outlet = true

  pdu_info.each do |a_pdu_info|
    measure_name = measurement_point_name(a_pdu_info, site)
    if site_pdu_outlets[measure_name] && site_pdu_outlets[measure_name] > 1
      per_outlet = false #at least two nodes are pointing to the same measurement point 
    else
      per_outlet = per_outlet && site_pdus[a_pdu_info['uid']] rescue nil
    end
  end

  if per_outlet.nil?
    node_monitoring_wattmeter = false
  elsif pdu_info.size > 1
    if per_outlet
      node_monitoring_wattmeter = 'multiple'
    else
      node_monitoring_wattmeter = 'multiple_shared'
    end
  else
    if per_outlet
      node_monitoring_wattmeter = true
    else
      node_monitoring_wattmeter = 'shared'
    end
  end
  node_monitoring_wattmeter
end

# Attempts to add information to data to help users
def annotate(data)
  data['sites'].each do |site_uid, site|
    site_pdus = {}
    site_pdu_outlets = {}
    metric_nodes = {}
    node_monitoring_wattmeter = {}
    # if site['clusters'].nil?
    #   return
    # end

    unless site['pdus'].nil?

      site['pdus'].each do |pdu_uid, pdu|
        pdu['uid'] = pdu_uid
        site_pdus[pdu['uid']] = pdu['sensors'][0]['power']['per_outlets'] rescue nil
        pp pdu if site_pdus[pdu['uid']].nil?
      end
      site['clusters'].each do |cluster_uid, cluster|
        cluster['nodes'].each do |node_uid, node|
          pdu_info = node['sensors']['power']['via']['pdu'] rescue nil
          unless pdu_info.nil?
            if pdu_info.size > 0 
              if pdu_info.first.is_a?(Array)
                pdu_info.each do |a_pdu_info|
                  count_measurement_points(a_pdu_info, site_pdu_outlets, site)
                end
              else
                count_measurement_points(pdu_info, site_pdu_outlets, site)
              end
            end
          end
        end
      end
      site['clusters'].each do |cluster_uid, cluster|

        cluster['nodes'].each do |node_uid, node|
          
          node_monitoring_wattmeter[node['uid']] = false
          pdu_info = node['sensors']['power']['via']['pdu'] rescue nil

          unless pdu_info.nil?

            # pdu_info is either
            # [{'uid' =>"parapluie-pdu-4", 'port' =>2}] in the simple case
            # [{'uid' =>"graphene-pdu9", 'port' =>23}, {'uid' =>"graphene-pdu9", 'port' =>24}] when plugged to 2 outlets
            # [[{'uid' =>"adonis-pdu-1", 'port' =>"outlet-11"}, {'uid' =>"adonis-pdu-1", 'port' =>"outlet-12"}], 
            #  [{'measure' =>"block-1", 'uid' =>"adonis-pdu-1"}]]
            raise ArgumentError, "Node #{node['uid']}['sensors']['power']['via']['pdu'] should be an Array" unless pdu_info.is_a?(Array)

            if pdu_info.size > 0 
              if pdu_info.first.is_a?(Array)
                # multiple measurement options : advertise the best
                priority = {
                  true => 5, 
                  'multiple' => 4, 
                  'shared' => 3, 
                  'multiple_shared' => 2, 
                  false => 1, 
                }
                node_monitoring_wattmeter[node['uid']] = false

                pdu_info.each do |a_pdu_info|
                  local_monitoring_wattmeter = monitoring_wattmeter_annotation(a_pdu_info, site_pdus, site_pdu_outlets, site)
                  if priority[local_monitoring_wattmeter] > priority[node_monitoring_wattmeter[node['uid']]]
                    node_monitoring_wattmeter[node['uid']] = local_monitoring_wattmeter
                  end
                end
              else 
                node_monitoring_wattmeter[node['uid']] = monitoring_wattmeter_annotation(pdu_info, site_pdus, site_pdu_outlets, site)
              end
            end               
          else
            ipmi_info = node['sensors']['power']['via']['ipmi'] rescue nil
            unless ipmi_info.nil?
              node_monitoring_wattmeter[node['uid']] = 'outofband'
            end
          end
        end
      end
    end
    site['clusters'].each do |cluster_uid, cluster|
      cluster['nodes'].each do |node_uid, node|
        node_monitoring_wattmeter[node['uid']] = false unless node_monitoring_wattmeter.has_key?(node['uid'])

        # Use strings instead of boolean as possible values are: true/false/shared/etc.
        node_monitoring_wattmeter[node['uid']] = "true"  if node_monitoring_wattmeter[node['uid']] == true
        node_monitoring_wattmeter[node['uid']] = "false" if node_monitoring_wattmeter[node['uid']] == false

        if node.has_key?('monitoring')
          if node['monitoring'].has_key?('wattmeter')
            if node['monitoring']['wattmeter'] != node_monitoring_wattmeter[node['uid']]
              puts "#{node['uid']}['monitoring']['wattmeter'] override calculated information with information found in input. Calculated it should be #{node_monitoring_wattmeter[node['uid']]}, keeping #{node['monitoring']['wattmeter']}"
            end
          else #create wattmeter entry
            pp 'Missing'
            node['monitoring']['wattmeter'] = node_monitoring_wattmeter[node['uid']]
          end
        else #create monitoring entry
          pp 'Missing'
          node['monitoring'] = {'wattmeter' => node_monitoring_wattmeter[node['uid']]}
        end
        #puts "#{node['uid']}['monitoring']['wattmeter'] = #{node['monitoring']['wattmeter']}"
      end
    end
  end
end
