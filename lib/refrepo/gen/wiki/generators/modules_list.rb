# coding: utf-8
require 'etc'
require 'net/ssh'



class ModulesList < WikiGenerator

    def get_modules_hash
        user, host = Etc.getpwuid[:name] == 'jenkins' ? ['ajenkins', 'lyon'] : ['g5kadmin', 'lyon.g5k']

        cmd = "/usr/share/lmod/lmod/libexec/spider -o jsonSoftwarePage $MODULEPATH"
        Net::SSH.start(host, user) do |ssh|
            output = ssh.exec!(cmd)
            return Hash[JSON.parse(output).map {|m| [m["package"], {"help": m["versions"][0]["help"], 
            "versions": m["versions"].map { |v| v["full"].split('/')[1]}}]}]
        end
    end

    def generate_content(_options)
        @generated_content = "{{Note|text=If you need additional software to be installed, feel free to contact [mailto:support-starff@lists.grid5000.fr Grid5000 support team] and we can look into it.}}\n\n"
        table_options = 'class="wikitable sortable"'
        table_data = []
        table_columns = ["Name", "Description", "Version(s)"]
        get_modules_hash().sort.each do |k, v|
            table_data << ["<span style='white-space: nowrap;'>'''#{k}'''</span>", 
                v[:help], 
                v[:versions].sort.join('<br/>')]
        end
        
        @generated_content = MW.generate_table(table_options, table_columns, table_data)
        @generated_content += MW.italic(MW.small(generated_date_string))
        @generated_content += MW::LINE_FEED
    end
end
