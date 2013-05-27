site :grenoble do |site_uid|
  2.times do |i|
    pdu "adonis-pdu-#{i+1}" do |pdu_uid|
      vendor "Eaton Corporation"
      model "ePDU C20 16A"
      sensors [
        {
          :power => [
            {
            :uid => "global",
              :measures => [
                {
                  :currentW => {
                    :unit => "W",
                    :shared => true,
                    :oid => ["iso.3.6.1.4.1.534.6.6.7.5.5.1.3.0.1"],
                    :api => "currentW"
                  }
                },
                {
                  :current => {
                    :unit => "VA",
                    :shared => "true",
                    :oid => ["iso.3.6.1.4.1.534.6.6.7.5.5.1.3.0.1"],
                    :api => "current"
                  }
                },
                {
                  :total => {
                    :unit => "Wh",
                    :shared => "true",
                    :oid => ["iso.3.6.1.4.1.534.6.6.7.5.5.1.3.0.1"],
                    :api => "total"
                  }
                }
              ]
            }
      ].concat(
            (1..2).map { |j|
              {
              :uid => "block-#{j}",
                :measures => [
                  {
                    :currentW => {
                      :unit => "W",
                      :shared => true,
                      :oid => ["iso.3.6.1.4.1.534.6.6.7.5.5.1.3.0.#{j}"],
                      :api => "block-#{j}-currentW"
                    }
                  },
                  {
                    :current => {
                      :unit => "VA",
                      :shared => "true",
                      :oid => ["iso.3.6.1.4.1.534.6.6.7.5.5.1.3.0.#{j}"],
                      :api => "block-#{j}-current"
                    }
                  },
                  {
                    :total => {
                      :unit => "Wh",
                      :shared => "true",
                      :oid => ["iso.3.6.1.4.1.534.6.6.7.5.5.1.3.0.#{j}",],
                      :api => "block-#{j}-total"
                    }
                  }
                ],
              :parent => "global"
              }
      }).concat(
          (0..1).collect { |k|
            (1..12).map { |j|
            #à faire 12 fois par block
            {
            :uid => "outlet-#{k*12+j}",
              :measures => [
                {
                  :currentW => {
                    :unit => "W",
                    :shared => true,
                    :oid => ["iso.3.6.1.4.1.534.6.6.7.5.5.1.3.0.#{k*12+j}"],
                    :api => "outlet-#{k*12+j}-currentW"
                  }
                },
                {
                  :current => {
                    :unit => "VA",
                    :shared => "true",
                    :oid => ["iso.3.6.1.4.1.534.6.6.7.5.5.1.3.0.#{k*12+j}"],
                    :api => "outlet-#{k*12+j}-current"
                  }
                },
                {
                  :total => {
                    :unit => "Wh",
                    :shared => "true",
                    :oid => ["iso.3.6.1.4.1.534.6.6.7.5.5.1.3.0.#{k*12+j}"],
                    :api => "outlet-#{k*12+j}-total"
                  }
                }
              ],
            :parent => "block-#{k+1}"
            }
            }
        }.flatten
      )
      }
      ]
    end
  end
end
