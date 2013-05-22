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
                    :unit => "W.h",
                    :shared => "true",
                    :oid => ["iso.3.6.1.4.1.534.6.6.7.5.5.1.3.0.1"],
                    :api => "total"
                  }
                }
              ]
            },
						#à faire 2 x
            {
            :uid => "block-1",
              :measures => [
                {
                  :currentW => {
                    :unit => "W",
                    :shared => true,
                    :oid => ["iso.3.6.1.4.1.534.6.6.7.5.5.1.3.0.1"],
                    :api => "block-1-currentW"
                  }
                },
                {
                  :current => {
                    :unit => "VA",
                    :shared => "true",
                    :oid => ["iso.3.6.1.4.1.534.6.6.7.5.5.1.3.0.1"],
                    :api => "block-1-current"
                  }
                },
                {
                  :total => {
                    :unit => "W.h",
                    :shared => "true",
                    :oid => ["iso.3.6.1.4.1.534.6.6.7.5.5.1.3.0.1",],
                    :api => "block-1-total"
                  }
                }
              ],
            :parent => "global"
            },
            #à faire 12 fois par block
            {
            :uid => "outlet-1",
              :measures => [
                {
                  :currentW => {
                    :unit => "W",
                    :shared => true,
                    :oid => ["iso.3.6.1.4.1.534.6.6.7.5.5.1.3.0.1"],
                    :api => "outlet-1-currentW"
                  }
                },
                {
                  :current => {
                    :unit => "VA",
                    :shared => "true",
                    :oid => ["iso.3.6.1.4.1.534.6.6.7.5.5.1.3.0.1"],
                    :api => "outlet-1-current"
                  }
                },
                {
                  :total => {
                    :unit => "W.h",
                    :shared => "true",
                    :oid => ["iso.3.6.1.4.1.534.6.6.7.5.5.1.3.0.1",
                    :api => "outlet-1-total"
                  }
                }
              ],
            :parent => "block-X"
            },
          ]
        }
      ]
    end
  end
end
