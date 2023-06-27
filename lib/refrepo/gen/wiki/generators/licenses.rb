# coding: utf-8

class LicensesGenerator < WikiGenerator

  def generate_content(_options)

    table_columns = ["Group", "Software", "Server", "Usage", "Allowed users"]
    table_data = []
    envs = []

    grps = RefRepo::Utils::get_api("users/groups")['items']
    grps.select!{|g| g['is_license'] }.select!{|g| g['enabled']}
    grps.each do |grp|
      table_data << [grp['name'], grp['payload']['software'], grp['payload']['server'], grp['payload']['usage'] || "-", grp['description'] || "-"]
    end

    # Table construction
    table_options = 'class="wikitable sortable" style="text-align: center;"'
    @generated_content = MW.generate_table(table_options, table_columns, table_data)
    @generated_content += MW.italic(MW.small("Last generated from the Grid'5000 API on #{Time.now.strftime("%Y-%m-%d")}"))
    @generated_content += MW::LINE_FEED
  end
end
