namespace :stereosupersonic do
  
    # from here => http://github.com/nesquena/cap-recipes  
    desc "Pings localhost to startup server"
    task :ping, :roles => :app do
      puts "Pinging the web server to start it"
      run "wget -O /dev/null #{local_ping_path} 2>/dev/null"
    end

   desc "Show gems"
   task :show_gems do
      stream "gem list"
   end

   desc "shows slowqueries"
   task :slow_queries do
      stream "sudo mysqldumpslow -s c /var/log/mysql/mysql-slow.log"
   end

   desc "shows the production log"
     task :production_log do
        stream "tail -f #{current_path}/log/production.log"
     end 


   desc "clears the cache"
   task :clear_cache  do
      run("cd #{current_path} rake cache:clear RAILS_ENV=production")
   end   
    desc "backup database to s3"
    task :backup_db_to_s3, :roles => :app do
      run "cd #{current_path} && rake db:backup_to_s3 RAILS_ENV=production --trace" do |channel, stream, data|
        puts "#{data}"
        break if stream == :err
      end
    end

   #from http://github.com/railsmachine/moonshine/blob/master/recipes/moonshine_cap.rb
   desc "remotely console"
   task :console, :roles => :app, :except => {:no_symlink => true} do
     input = ''
     run "cd #{current_path} && ./script/console #{fetch(:rails_env, "production")}" do |channel, stream, data|
       next if data.chomp == input.chomp || data.chomp == ''
       print data
       channel.send_data(input = $stdin.gets) if data =~ /^(>|\?)>/
     end
   end

   desc "Show requests per second"
   task :rps, :roles => :app, :except => {:no_symlink => true} do
     count = 0
     last = Time.now
     run "tail -f #{shared_path}/log/#{fetch(:rails_env, "production")}.log" do |ch, stream, out|
       break if stream == :err
       count += 1 if out =~ /^Completed in/
       if Time.now - last >= 1
         puts "#{ch[:host]}: %2d Requests / Second" % count
         count = 0
         last = Time.now
       end
     end
   end

   desc "tail application log file"
   task :log, :roles => :app, :except => {:no_symlink => true} do
     run "tail -f #{shared_path}/log/#{fetch(:rails_env, "production")}.log" do |channel, stream, data|
       puts "#{data}"
       break if stream == :err
     end
   end

   desc "tail vmstat"
   task :vmstat, :roles => [:web, :db] do
     run "vmstat 5" do |channel, stream, data|
       puts "[#{channel[:host]}]"
       puts data.gsub(/\s+/, "\t")
       break if stream == :err
     end
   end
   
end