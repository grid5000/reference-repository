require 'refrepo/data_loader'

def nodes_by_model(model)
  nodes = []
  data = load_data_hierarchy
  data['sites'].keys.each do |site|
    data['sites'][site]['clusters'].each do |cluster|
      c = cluster.last
      c['nodes'].each do |_, v|
        nodes << v
      end
    end
  end
  model_filter = nodes.select do |node|
    node['chassis']['name'] =~ /#{model}/
  end
  model_filter
end

def get_firmware_version(devices)
  version = Hash.new
  devices.each do |device|
    if device.has_key?("firmware_version")
      version[device['model']] = device['firmware_version']
    end
  end
  version
end

class Hash
  def except(*keys)
    hash = self
    desired_keys = hash.keys - keys
    Hash[ [desired_keys, hash.values_at(*desired_keys)].transpose]
  end
end

def gen_firmwares_tables
  data = load_data_hierarchy
  # nodes table
  d = []
  data['sites'].keys.each do |site|
    data['sites'][site]['clusters'].keys.each do |cluster|
       nodes = data['sites'][site]['clusters'][cluster]['nodes'].values.map do |e|
         {
           'uid' => e['uid'],
           'chassis_manufacturer' => e['chassis']['manufacturer'],
           'chassis_name' => e['chassis']['name'],
           'bmc_version' => e['bmc_version'],
           'bios_release_date' => e['bios']['release_date'],
           'bios_version' => e['bios']['version']
         }
       end
       nodesets = nodes.group_by { |e| e.except('uid') }.map do |e|
         e[1] = e[1].map { |f| f['uid'] } ; e
         e[1] = `echo #{e[1].join(',')} | nodeset -f`.chomp
         e
       end
       nodesets.each do |e|
         h = { 'site' => site, 'cluster' => cluster, 'nodes' => e[1] }
         h.merge!(e[0])
         d << h
       end
    end
  end

  puts <<-EOF
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Bugzilla summary</title>
<!-- Latest compiled and minified CSS -->
<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css" integrity="sha384-HSMxcRTRxnN+Bdg0JdbxYKrThecOKuH5zCYotlSAcp1+c8xmyTe9GYg1l9a69psu" crossorigin="anonymous">

<!-- Optional theme -->
<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap-theme.min.css" integrity="sha384-6pzBo3FDv/PJ8r2KRkGHifhEocL+1X2rVCTTkUfGk7/0pbek5mMa1upzvWbrUbOZ" crossorigin="anonymous">

<script src="https://code.jquery.com/jquery-2.2.4.min.js" integrity="sha256-BbhdlvQf/xTY9gja0Dq3HiwQF8LaCRTXxZKRutelT44=" crossorigin="anonymous"></script>
<script src="https://stackpath.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js" integrity="sha384-aJ21OjlMXNL5UyIl/XNwTMqvzeRMZH2w8c5cRVpzpU8Y5bApTppSuUkhZXN0VxHd" crossorigin="anonymous"></script>

<!-- Datatables -->
<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/1.10.20/css/dataTables.bootstrap.min.css">
<script type="text/javascript" charset="utf-8" src="https://cdn.datatables.net/1.10.20/js/jquery.dataTables.min.js"></script>
<script type="text/javascript" charset="utf-8" src="https://cdn.datatables.net/1.10.20/js/dataTables.bootstrap.min.js"></script>
</head>

<body data-spy="scroll">
<div class="container-fluid">
<h3>Nodes</h3>
  <div class="table-responsive"><div class='container-fluid'>
   <table id="table0" class="table table-bordered table-hover table-condensed text-center table-reducedrowheight">
     <thead>
       <tr>
         <th class="text-center">Site</th>
         <th class="text-center">Cluster</th>
         <th class="text-center">Nodes</th>
         <th class="text-center">Manufacturer</th>
         <th class="text-center">Model</th>
         <th class="text-center">BMC</th>
         <th class="text-center">BIOS date</th>
         <th class="text-center">BIOS version</th>
       </tr>
     </thead>
     <tfoot style="display: table-header-group;">
     <tr>
       <td><input type="text" placeholder="" size="2" style="width:100%;" /></td>
       <td><input type="text" placeholder="" size="2" style="width:100%;" /></td>
       <td><input type="text" placeholder="" size="2" style="width:100%;" /></td>
       <td><input type="text" placeholder="" size="2" style="width:100%;" /></td>
       <td><input type="text" placeholder="" size="2" style="width:100%;" /></td>
       <td><input type="text" placeholder="" size="2" style="width:100%;" /></td>
       <td><input type="text" placeholder="" size="2" style="width:100%;" /></td>
       <td><input type="text" placeholder="" size="2" style="width:100%;" /></td>
     </tr>
     </tfoot>
     <tbody>
     EOF
     d.each do |r|
       puts <<-EOF
<tr>
<td class="text-nowrap">#{r['site']}</td>
<td class="text-nowrap">#{r['cluster']}</td>
<td class="text-nowrap">#{r['nodes']}</td>
<td class="text-nowrap">#{r['chassis_manufacturer']}</td>
<td class="text-nowrap">#{r['chassis_name']}</td>
<td class="text-nowrap">#{r['bmc_version']}</td>
<td class="text-nowrap">#{r['bios_release_date']}</td>
<td class="text-nowrap">#{r['bios_version']}</td>
      </tr>
      EOF
     end
     puts <<-EOF
             </tbody>
   </table>
   </div>
   </div>
   </div>
  <script type="text/javascript" class="init">
    $('#table0').DataTable(
         { "bPaginate": false, }
    ).columns().every( function () {
      var that = this;

      $( 'input', this.footer() ).on( 'keyup change', function () {
        if ( that.search() !== this.value ) {
          that
            .search( this.value )
            .draw();
        }
      } );
    } );
</script>
</body>
</html>
  EOF
end
