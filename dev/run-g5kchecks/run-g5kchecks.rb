require 'cute'
require 'peach'
require 'fileutils'
require 'pp'

options ||= {}
options[:ssh] ||= {}
options[:ssh][:user] = 'g5kadmin'    unless options[:ssh][:user]
options[:ssh][:host] = '%s.g5kadmin' unless options[:ssh][:host]
options[:ssh][:params] ||= {:timeout => 10}

options[:queue] = 'admin'
options[:queue] = 'default'

jobs = []

FileUtils::mkdir_p("output/")

begin

  g5k = Cute::G5K::API.new()

  g5k.site_uids().peach { |site_uid|

    #
    # Node reservation
    #

    # Reserve as many free node as possible in one reservation
    begin
      jobs << g5k.reserve(:site => site_uid, :resources => "nodes=BEST", :walltime => '00:30:00', :wait => false, :queue => options[:queue])
    rescue Exception => e
        puts "#{site_uid}: Error during the reservation nodes=BEST"
    end

    # Reserve busy nodes one by one
    g5k.nodes_status(site_uid).each { |node_uid, status|
      next if File.exist?("output/#{node_uid}.yaml") # skip reservation if we alread have the node info
      next if status != "busy"                       # only busy nodes

      begin
        jobs << g5k.reserve(:site => site_uid, :resources => "{host='#{node_uid}'}", :walltime => '00:30:00', :wait => false, :queue => options[:queue])
      rescue Exception => e
        puts "#{site_uid}: Error during the reservation of #{node_uid} - #{e.class}: #{e.message}"
      end
    }

    #
    # Process running jobs
    #
    
    released_jobs = {};

    loop do
      waiting_jobs   = g5k.get_my_jobs(site_uid, state='waiting')
      running_jobs   = g5k.get_my_jobs(site_uid, state='running')
      launching_jobs = g5k.get_my_jobs(site_uid, state='launching')

      puts "#{site_uid}: Running: #{running_jobs.size} - Waiting: #{waiting_jobs.size} - Launching: #{launching_jobs.size}"

      running_jobs.each { |job|
        job_uid = job['uid']
        if released_jobs[job_uid]
          puts "#{site_uid}: #{job_uid} already processed"
          next
        end

        puts "#{site_uid}: Processing #{job_uid}"

        job['assigned_nodes'].peach(10) { |node_uid|

          next if File.exist?("output/#{node_uid}.yaml")

          puts "#{site_uid}: Processing #{job_uid} - #{node_uid}"
          begin
            Net::SSH.start(options[:ssh][:host].gsub("%s", site_uid), options[:ssh][:user], options[:ssh][:params]) { |ssh|
              output1 = ssh.exec!("sudo ssh -o StrictHostKeychecking=no root@#{node_uid} '/usr/bin/g5k-checks -m api'")
              output2 = ssh.exec!("sudo ssh -q -o StrictHostKeychecking=no root@#{node_uid} 'cat /tmp/#{node_uid}.yaml'")
              
              File.open("output/#{node_uid}.yaml", 'w') do |f|
                f.write(output2)
              end
            }
          rescue Exception => e
            puts "#{site_uid}: Error while processing #{job_uid} - #{node_uid} - #{e.class}: #{e.message}"
          end
          
        }
        
        puts "#{site_uid}: Release #{job_uid}"
        begin
          g5k.release(job)
          released_jobs[job_uid] = true
        rescue Exception => e
          puts "#{site_uid}: Error while releasing job #{job_uid} - #{e.class}: #{e.message}"
        end
      }

      # Stop when there isn't any job left
      break    if running_jobs.empty? and waiting_jobs.empty? and launching_jobs.empty?

      # Wait a little bit when the previous loop iteration did not find any job to process
      sleep(5) if running_jobs.empty?
      
    end

  }

rescue Exception => e
  puts "#{e.class}: #{e.message}"
ensure
  jobs.each { |job| 
    puts "Release job #{job['links'][0]['href']}"
    g5k.release(job) 
  }
end
