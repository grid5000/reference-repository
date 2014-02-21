site :lyon do |site_uid|
  pdu "wattmetre" do |pdu_uid|
    vendor "OmegaWatt"
    model ""
    sensors [
      {
        :power => {
          :per_outlets => true,
          :wattmetre => {
            :available => true,
            :www => { :url => 'http://wattmetre.lyon.grid5000.fr/GetWatts-json.php' },
            :unit => "W",
          }
        }
      }
    ]
  end
end
