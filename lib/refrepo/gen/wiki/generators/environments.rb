# coding: utf-8

class EnvironmentsGenerator < WikiGenerator

  OSVERSION_SORT_ORDER = ['debian9','debian10','debian11','debiantesting','centos7','centos8','rocky8','centosstream8','ubuntu1804','ubuntu2004']
  VARIANT_SORT_ORDER = ['min','base', 'xen', 'nfs', 'big', 'std']

  def initialize(page_name)
    super(page_name)
  end

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
    table_columns += envs.map{|x| x['arch']}.uniq.sort
    envs = envs.group_by{|x| x['name']}.map{|k,v| [k,v.map{|x| x['arch']}]}
    envs.each do |env|
      tarch = table_columns[1..3].map{|l| env[1].include?(l) ? '[[Image:Check.png]]' : '[[Image:NoStarted.png]]' }
      table_data << [env[0]] + tarch
    end

    # Sort by OS version and variant
    table_data.sort_by! { |row|
      [OSVERSION_SORT_ORDER.index(row[0].split('-')[0]) || 100, VARIANT_SORT_ORDER.index(row[0].split('-')[1]) || 100]
    }

    # Table construction
    table_options = 'class="wikitable sortable" style="text-align: center;"'
    @generated_content = MW.generate_table(table_options, table_columns, table_data)
    @generated_content += MW.italic(MW.small(generated_date_string))
    @generated_content += MW::LINE_FEED
  end
end
