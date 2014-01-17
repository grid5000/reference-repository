site :rennes do |site_uid|

  8.times do |i|
    pdu "paradent-pdu-#{i+1}" do |pdu_uid|
      vendor "Amazing PDU"
      model "AMz-1623F-16-1"
      sensors [
        {
          :power => {
            :per_outlets => false,
            :snmp => {
              :available => true,
              :total_oids => ["iso.3.6.1.4.1.17420.1.2.9.1.11.0"],
              :unit => "dA"
            }
          }
        }
      ]
    end
  end

  4.times do |i|
    pdu "parapide-pdu-#{i+1}" do |pdu_uid|
      vendor "APC"
      model "AP7851"
      sensors [
        {
          :power => {
            :per_outlets => false,
            :snmp => {
              :available => true,
              :total_oids => ["iso.3.6.1.4.1.318.1.1.12.1.16.0"],
              :unit => "W"
            }
          }
        }
      ]
    end
  end

  6.times do |i|
    pdu "parapluie-pdu-#{i+1}" do |pdu_uid|
      vendor "Eaton Corporation"
      model ""
      sensors [
        {
          :power => {
            :per_outlets => true,
            :snmp => {
              :available => true,
              :total_oids => ["iso.3.6.1.4.1.534.6.6.7.5.5.1.3.0.1", "iso.3.6.1.4.1.534.6.6.7.5.5.1.3.0.2"],
              :unit => "W",
              :outlet_prefix_oid => "iso.3.6.1.4.1.534.6.6.7.6.5.1.3.0"
            }
          }
        }
      ]
    end
  end

end
