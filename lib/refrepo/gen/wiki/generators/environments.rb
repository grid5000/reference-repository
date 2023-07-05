# coding: utf-8

class EnvironmentsGenerator < WikiGenerator

  OSVERSION_SORT_ORDER = ['debian10','debian11','debiantesting','centos7','centos8','rocky8','rocky9','centosstream8','centosstream9','ubuntu2004', 'ubuntu2204']
  VARIANT_SORT_ORDER = ['min','base','xen', 'nfs', 'big', 'std']
  # FIXME Update the description of envs to something more sensible instead of overwriting here.
  DESC = {
    'debian10-min' => 'debian 10 (buster) minimalistic installation',
    'debian10-base' => 'debian 10 (buster) with various Grid\'5000-specific tuning for performance',
    'debian10-xen' => 'debian 10 (buster) with Xen hypervisor Dom0 + minimal DomU',
    'debian10-nfs' => 'debian 10 (buster) with support for mounting NFS home',
    'debian10-big' => 'debian 10 (buster) with packages for development, system tools, editors, shells.',
    'debian11-min' => 'debian 11 (bullseye) minimalistic installation',
    'debian11-base' => 'debian 11 (bullseye) with various Grid\'5000-specific tuning for performance',
    'debian11-xen' => 'debian 11 (bullseye) with Xen hypervisor Dom0 + minimal DomU',
    'debian11-nfs' => 'debian 11 (bullseye) with support for mounting NFS home',
    'debian11-big' => 'debian 11 (bullseye) with packages for development, system tools, editors, shells.',
    'ubuntu2004-min' => 'ubuntu 20.04 (focal) minimalistic installation',
    'ubuntu2004-nfs' => 'ubuntu 20.04 (focal) with support for mounting NFS home',
    'ubuntu2204-min' => 'ubuntu 22.04 (jellyfish) minimalistic installation',
    'ubuntu2204-nfs' => 'ubuntu 22.04 (jellyfish) with support for mounting NFS home',
    'centos7-min' => 'centos 7 minimalistic installation',
    'centos7-nfs' => 'centos 7 with support for mounting NFS home',
    'centos8-min' => 'centos 8 minimalistic installation',
    'centos8-nfs' => 'centos 8 with support for mounting NFS home',
    'centosstream8-min' => 'centos-stream 8 minimalistic installation',
    'centosstream8-nfs' => 'centos-stream 8 with support for mounting NFS home',
    'centosstream9-min' => 'centos-stream 9 minimalistic installation',
    'centosstream9-nfs' => 'centos-stream 9 with support for mounting NFS home',
    'rocky8-min' => 'rocky 8 minimalistic installation',
    'rocky8-nfs' => 'rocky 8 with support for mounting NFS home',
    'rocky9-min' => 'rocky 9 minimalistic installation',
    'rocky9-nfs' => 'rocky 9 with support for mounting NFS home',
    'debiantesting-min' => 'debian testing minimalistic installation',
    'debiantesting-nfs' => 'debian testing with support for mounting NFS home',
  }

  def generate_content(_options)

    table_columns = ["Name"]
    table_data = []
    envs = []

    G5K::SITES.each do |site|
      envs += RefRepo::Utils::get_api("sites/#{site}/internal/kadeployapi/environments?username=deploy&last")
    end
    envs.select!{|x| x['visibility'] == 'public'}
    # The creation date can be a little different on each site, we remove it from hash before removing dupplicate
    envs.each{|x| x.delete('created_at')}
    envs.uniq!
    # FIXME We reject debian11-std here until #13183 is fixed
    envs.reject!{|x| x['name'] == 'debian11-std'}
    table_columns += envs.map{|x| x['arch']}.uniq.sort.reverse
    table_columns << 'Description'
    envs = envs.group_by{|x| x['name']}.map{|k,v| [k,v.map{|x| x['arch']}, v.first['description']]}
    envs.each do |env|
      tarch = table_columns[1..3].map{|l| env[1].include?(l) ? '[[Image:Check.png]]' : '[[Image:NoStarted.png]]' }
      table_data << [env[0]] + tarch + [DESC[env[0]] || env[2]]
    end

    # Sort by OS version and variant
    table_data.sort_by! { |row|
      [OSVERSION_SORT_ORDER.index(row[0].split('-')[0]) || 100, VARIANT_SORT_ORDER.index(row[0].split('-')[1]) || 100]
    }

    # Table construction
    table_options = 'class="wikitable sortable" style="text-align: center;"'
    @generated_content = MW.generate_table(table_options, table_columns, table_data)
    @generated_content += MW.italic(MW.small("Last generated from the Grid'5000 API on #{Time.now.strftime("%Y-%m-%d")}"))
    @generated_content += MW::LINE_FEED
  end
end
