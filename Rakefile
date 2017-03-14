
REFAPI_DIR = "./generators/reference-api"
PUPPET_DIR = "./generators/puppet"
OAR_DIR = "./generators/oar-properties"
VALIDATORS_DIR = "./generators/input-validators"

namespace :puppet do

  all_puppet_tasks = [:bindg5k, :conmang5k, :dhcpg5k, :kadeployg5k, :lanpowerg5k]

  all_puppet_tasks.each { |t|
    desc "Generate #{t} configuration"
    task t do
      puts "#{PUPPET_DIR}/#{t}.rb #{$CMD_ARGS}"
      ruby "#{PUPPET_DIR}/#{t}.rb #{$CMD_ARGS}"
    end
  }

  desc "Launch all puppet generators"
  task :all => all_puppet_tasks

end

namespace :oar do

  desc "Generate oar properties"
  task :properties do
    puts "#{OAR_DIR}/oar-properties.rb #{$CMD_ARGS}"
    ruby "#{OAR_DIR}/oar-properties.rb #{$CMD_ARGS}"
  end

end

namespace :validators do

  desc "Check homogeneity of clusters"
  task "homogeneity" do
    puts "ruby #{VALIDATORS_DIR}/check-cluster-homogeneity.rb #{$CMD_ARGS}"
    system ("ruby #{VALIDATORS_DIR}/check-cluster-homogeneity.rb #{$CMD_ARGS}")
  end

  desc "Check input data schema validity"
  task "schema" do
    puts "ruby #{VALIDATORS_DIR}/yaml-input-schema-validator.rb #{$CMD_ARGS}"
    system ("ruby #{VALIDATORS_DIR}/yaml-input-schema-validator.rb #{$CMD_ARGS}")
  end
end

desc "Creates json data from inputs"
task "reference-api" => ["validators:homogeneity", "validators:schema"] do
  #no args needed here
  puts "#{REFAPI_DIR}/reference-api.rb"
  ruby "#{REFAPI_DIR}/reference-api.rb"
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
