
REFAPI_DIR = "./generators/reference-api"
PUPPET_DIR = "./generators/puppet"
OAR_DIR = "./generators/oar-properties"
VALIDATORS_DIR = "./generators/input-validators"
WIKI_DIR = "./generators/wiki"

namespace :puppet do

  all_puppet_tasks = [:bindg5k, :conmang5k, :dhcpg5k, :kadeployg5k, :lanpowerg5k, :kavlang5k]

  all_puppet_tasks.each { |t|
    desc "Generate #{t} configuration"
    task t do
      invoke_script "#{PUPPET_DIR}/#{t}.rb"
    end
  }

  desc "Launch all puppet generators"
  task :all => all_puppet_tasks

end

namespace :oar do

  desc "Generate oar properties"
  task :properties do
    invoke_script "#{OAR_DIR}/oar-properties.rb"
  end

end

namespace :validators do

  desc "Check homogeneity of clusters"
  task "homogeneity" do
    invoke_script "#{VALIDATORS_DIR}/check-cluster-homogeneity.rb"
  end

  desc "Check input data schema validity"
  task "schema" do
    invoke_script "#{VALIDATORS_DIR}/yaml-input-schema-validator.rb"
  end
end

namespace :wiki do

  all_wiki_tasks = [:cpu_parameters, :oar_properties, :disk_reservation, :hardware, :site_hardware, :site_network]

  all_wiki_tasks.each { |t|
    desc "Generate the media parts for #{t}"
    task t do
      invoke_script "#{WIKI_DIR}/#{t}.rb"
    end
  }

  desc "Launch all wiki generators"
  task :all => all_wiki_tasks

end

desc "Creates json data from inputs"
task "reference-api" do
  invoke_script "#{REFAPI_DIR}/reference-api.rb"
end

#Some scripts may return status != 0 (validators, errors, ...)
#Catch errors and exit properly with status 1 instead of getting Rake errors
def invoke_script(script)
  puts "Running #{script} #{$CMD_ARGS}"
  begin
    ruby "#{script} #{$CMD_ARGS}"
  rescue => e
    exit 1
  end
end

#Hack rake: call only the first task and consider the rest as arguments to this task
currentTask = Rake.application.top_level_tasks.first
taskNames = Rake.application.tasks().map { |task| task.name() }
if (taskNames.include?(currentTask))
  Rake.application.instance_variable_set(:@top_level_tasks, [currentTask])
  ARGV.shift(ARGV.index(currentTask) + 1)
  $CMD_ARGS = ARGV.map{|arg| "'#{arg}'"}.join(' ')
else
  #Not running any task, maybe rake options, invalid, etc...
end
