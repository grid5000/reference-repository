=begin
We need:
* linecard model
* equipment backplance capacity
* description of high perf networks, with corresponding equipments
* solving issues regarding node naming (-ib0, -myri0, what does it mean when there is nothing?)
* virtual equipments
=end


# Common generation engine.
# You can overwrite later on, to add networks, etc.
%w{lille nancy lyon}.each do |site_uid|
  site site_uid.to_sym do
    lookup("#{site_uid}-network-equipments").each do |equipment_uid, properties|
      network_equipment equipment_uid do |equiment_uid|
        model properties['model']
        mac properties['mac']
        kind properties['kind']
        # Group equipment connections by linecard
        connections_by_linecard = properties['connections'].group_by{|c|
          c['linecard']
        }
        max_linecard = connections_by_linecard.keys.max
        # Define linecards
        linecards(
          (0..max_linecard).map{|linecard_i|
            # Group linecard connections par port
            ports = connections_by_linecard[linecard_i]
            if ports
              connections_by_port = ports.index_by{|p| p['port']}
              max_port = connections_by_port.keys.max
              {
                # :model => nil,
                # :rate => nil,
                # Are ports indexed from 0 or 1??
                :ports => (0..max_port).map{|port_i|
                  h = connections_by_port[port_i] || {}
                  h.delete('linecard')
                  h.delete('port')
                  h.delete('trunked') unless h['trunked']
                  h
                }
              }
            else
              {}
            end
          }

        )

        trunks properties['trunks']
      end
    end
  end
end

site "lille" do
  network_equipment "gw" do
    networks [
      {
        :kind     => 'default',
        :cidr    => '192.168.159.0/24'
      },
      {
        :kind     => 'virtual',
        :cidr    => '10.136.0.0/14'
      }
      # TODO:kavlan, add gateway
    ]
  end

  # switch myrinet 10G?
end

site "lyon" do
  network_equipment "gw" do
    networks [
      {
        :kind     => 'default',
        :cidr    => '10.69.0.0/21'
      },
      {
        :kind     => 'virtual',
        :cidr    => '10.140.0.0/14'
      }

      # TODO:kavlan, add gateway
    ]
  end

  # What about capricorne switch with myrinet?
  # network_equipment "missing"
end


site "nancy" do
  network_equipment "gw" do
    networks [
      {
        :kind     => 'default',
        :cidr    => '172.16.64.0/20'
      },
      {
        :kind     => 'virtual',
        :cidr    => '10.144.0.0/14'
      }
      # Infiniband??
      # sgriffon description does not declare -ib0
      #
      # TODO:kavlan, add gateway
    ]
  end
end

#TODO: SOPHIA, description file has to be redone.


network_equipment "renater5-paris" do
  kind :virtual

  linecards [
    {
      # :rate => ?,
      :ports => [
        {
          :uid      => "renater5-lille",
          :kind     => "virtual",
          :linecard => 0,
          :port     => 0,
          :rate     => 10.G
        },
        {
          :uid      => "renater5-lyon",
          :kind     => "virtual",
          :linecard => 0,
          :port     => 0,
          :rate     => 10.G
        },
        {
          :uid      => "renater5-nancy",
          :kind     => "virtual",
          :linecard => 0,
          :port     => 0,
          :rate     => 10.G
        },
        # ...
      ]
    }
  ]
end

network_equipment "renater5-lille" do
  kind :virtual

  linecards [
    {
      # :rate => ?,
      :ports => [
        {
          :uid      => "renater5-paris",
          :kind     => "virtual",
          :linecard => 0,
          :port     => 0,
          :rate     => 10.G
        },
        {
          :uid      => "gw",
          :kind     => "router",
          :site_uid => "lille",
          # to which linecard/port is it connected ?
          # ...
        }
      ]
    }
  ]
end

network_equipment "renater5-lyon" do
  kind :virtual

  linecards [
    {
      # :rate => ?,
      :ports => [
        {
          :uid      => "renater5-paris",
          :kind     => "virtual",
          :linecard => 0,
          :port     => 1,
          :rate     => 10.G
        },
        {
          :uid      => "gw",
          :kind     => "router",
          :site_uid => "lyon",
          # to which linecard/port is it connected ?
          # ...
        },
      ]
    }
  ]
end


network_equipment "renater5-nancy" do
  kind :virtual

  linecards [
    {
      # :rate => ?,
      :ports => [
        {
          :uid      => "renater5-paris",
          :kind     => "virtual",
          :linecard => 0,
          :port     => 2,
          :rate     => 10.G
        },
        {
          :uid      => "gw",
          :kind     => "router",
          :site_uid => "nancy",
          # to which linecard/port is it connected ?
          # ...
        },
      ]
    }
  ]
end
