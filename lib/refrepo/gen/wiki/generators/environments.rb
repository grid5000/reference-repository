class EnvironmentsGenerator < WikiGenerator
  OSVERSION_SORT_ORDER = %w[debian10 debian11 debiantesting centos7 centos8 rocky8 rocky9 centosstream8
                            centosstream9 ubuntu2004 ubuntu2204]
  VARIANT_SORT_ORDER = %w[min base nfs big std]
  # FIXME: Update the description of envs to something more sensible instead of overwriting here.
  DESC = {
    'debian11-min' => 'debian 11 (bullseye) minimalistic installation',
    'debian11-base' => 'debian 11 (bullseye) with various Grid\'5000-specific tuning for performance',
    'debian11-nfs' => 'debian 11 (bullseye) with support for mounting NFS home',
    'debian11-big' => 'debian 11 (bullseye) with packages for development, system tools, editors, shells.',
    'debian12-min' => 'debian 12 (bookworm) minimalistic installation',
    'debian12-nfs' => 'debian 12 (bookworm) with support for mounting NFS home',
    'debian12-big' => 'debian 12 (bookworm) with packages for development, system tools, editors, shells.',
    'debiab13-min' => 'debian 13 (trixie) minimalistic installation',
    'debian13-nfs' => 'debian 13 (trixie) with support for mounting NFS home',
    'debiantesting-min' => 'debian testing minimalistic installation',
    'debiantesting-nfs' => 'debian testing with support for mounting NFS home',
    'ubuntu2004-min' => 'ubuntu 20.04 (focal) minimalistic installation',
    'ubuntu2004-nfs' => 'ubuntu 20.04 (focal) with support for mounting NFS home',
    'ubuntu2204-min' => 'ubuntu 22.04 (jellyfish) minimalistic installation',
    'ubuntu2204-nfs' => 'ubuntu 22.04 (jellyfish) with support for mounting NFS home',
    'ubuntu2404-min' => 'ubuntu 22.04 (noble) minimalistic installation',
    'ubuntu2404-nfs' => 'ubuntu 24.04 (noble) with support for mounting NFS home',
    'centosstream9-min' => 'centos-stream 9 minimalistic installation',
    'centosstream9-nfs' => 'centos-stream 9 with support for mounting NFS home',
    'rocky8-min' => 'rocky 8 minimalistic installation',
    'rocky8-nfs' => 'rocky 8 with support for mounting NFS home',
    'rocky9-min' => 'rocky 9 minimalistic installation',
    'rocky9-nfs' => 'rocky 9 with support for mounting NFS home',
    'almalinux9-min' => 'almalinux 9 minimalistic installation',
    'almalinux9-nfs' => 'almalinux 9 with support for mounting NFS home'
  }

  def generate_content(_options)
    table_columns = ['Name']
    table_data = []
    envs = []

    G5K::SITES.each do |site|
      envs += RefRepo::Utils.get_api("sites/#{site}/environments")['items']
    end
    envs.select! { |x| x['visibility'] == 'public' }
    # The creation date can be a little different on each site, we remove it from hash before removing dupplicate
    envs.each { |x| x.delete('created_at') }
    envs.uniq!
    table_columns += envs.map { |x| x['arch'] }.uniq.sort.reverse
    table_columns << 'Description'
    envs = envs.group_by { |x| x['name'] }.map { |k, v| [k, v.map { |x| x['arch'] }, v.first['description']] }
    envs.each do |env|
      tarch = table_columns[1..3].map { |l| env[1].include?(l) ? '[[Image:Check.png]]' : '[[Image:NoStarted.png]]' }
      table_data << [env[0]] + tarch + [DESC[env[0]] || env[2]]
    end

    # Sort by OS version and variant
    table_data.sort_by! do |row|
      [OSVERSION_SORT_ORDER.index(row[0].split('-')[0]) || 100, VARIANT_SORT_ORDER.index(row[0].split('-')[1]) || 100]
    end

    # Table construction
    table_options = 'class="wikitable sortable" style="text-align: center;"'
    @generated_content = MW.generate_table(table_options, table_columns, table_data)
    @generated_content += MW.italic(MW.small("Last generated from the Grid'5000 API on #{Time.now.strftime('%Y-%m-%d')}"))
    @generated_content += MW::LINE_FEED
  end
end
