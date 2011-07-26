namespace :db do
  def app_config(key)
   APP_CONFIG[key.to_sym]
  end
  
  def application
    Rails.application.class.to_s.split("::").first.downcase
  end

  def target_dump(app)
    "/tmp/#{local_db(app)}.sql"
  end

  def local_db(app)
    "#{app}_#{env}"
  end

  def prod_db(app)
    "#{app}_production"
  end

  def source_dump(app)
    "~/#{prod_db(app)}.sql"
  end

  def target_dump(app)
    "/tmp/#{app}.sql"
  end

  def dbuser
    db_config[env]["username"]
  end

  def dbpw
    db_config[env]["password"]
  end

  def dbhost
    db_config[env]["host"]
  end


  def dbname
    db_config[env]["database"]
  end
  
  def dump_optins
    #--single-transaction --flush-logs --add-drop-table --add-locks --create-options --disable-keys --extended-insert --quick
     "--opt"
  end

  def env
    Rails.env.downcase
  end

  def mysql_params
    "-u #{dbuser || 'root'} #{dbpw ? '-p'+ dbpw : ''} #{dbhost ? ' -h '+dbhost : ' '}"
  end   

  def db_config
    @conf ||=  YAML.load_file("#{Rails.root}/config/database.yml")
  end
  
  def host 
     app_config :host
  end
  
  def ssh_user_production 
    app_config :ssh_user_production
  end
  
  def dump_filename
    "#{Time.now.strftime '%d.%m.%Y_%H:%M'}_#{env}_dump.sql"
  end
  
  def dump_filename_gz
    "#{dump_filename}.gz"
  end
  
  def backup_path    
    backup_path = File.join(Rails.root,'log','dumps')
    FileUtils.mkdir_p backup_path
    backup_path
  end
  
  task :migrate do
    #annotate the models after migration
    if Rails.env.development?
      require 'annotate_models'
      AnnotateModels.do_annotations
    end
  end
  
  task :save_dump_file => :environment do 
    backup_file = File.join(backup_path, dump_filename)
    system "cp #{target_dump(application)} #{backup_file}"
     Rake::Task['db:remove_unwanted_backup_base'].invoke
  end
  
  desc "remove old backups"
  task :remove_unwanted_backup_base => :environment do
    all_backups =  Dir.new(backup_path).entries[2..-1].sort { |a,b| File.mtime(File.join(backup_path,a)) <=> File.mtime(File.join(backup_path,b)) }.reverse
    max_backups =  20
    unwanted_backups = all_backups[max_backups..-1] || []
    for unwanted_backup in unwanted_backups
      FileUtils.rm_rf(File.join(backup_path, unwanted_backup))
      puts "deleted #{unwanted_backup}" 
    end
  end

  task :create_dump, [:filename]  do |t, args|
    file = args.filename ? args.filename : "#{Rails.root}/dumps/#{dump_filename}"
    system "mysqldump #{mysql_params} #{dump_optins} #{dbname} > #{file} "
  end

  task :download_dump => :environment do
    puts "Hole Dump fuer #{application} in #{env} auf #{host}"
    
    target_dump = target_dump(application)
    target_dump_gz = "#{target_dump(application)}.gz"
    
    system "rm #{target_dump}"   
    sh "ssh #{ssh_user_production}@#{host} \"mysqldump -u #{db_config['production']["username"]} -p#{db_config['production']["password"]} -h #{db_config['production']["host"] } #{dump_optins} #{db_config['production']["database"]} > #{source_dump(application)} && gzip -c #{source_dump(application)} > #{source_dump(application)}.gz\""
    sh "scp -C #{ssh_user_production}@#{host}:#{source_dump(application)}.gz #{target_dump_gz}"
    sh "gzip -dc #{target_dump_gz} > #{target_dump}"
    puts "Download fertig!!! Datei Size: #{File.size(target_dump_gz)} - Datum: #{File.mtime(target_dump_gz).strftime '%d.%m.%Y %H:%M'}"
    FileUtils.rm target_dump_gz
  end

  desc "insert a dump into the local development db"
  task :import_from_file, [:filename]  do |t, args|
    file = args.filename ? args.filename : "db/production_data.sql"
    raise "keine Datei angegeben" if file.nil? 
    raise "Datei #{file} ist nicht vorhanden" unless File.exists? file
 

    puts "Importiere in DB: #{local_db(application)} den Dump: #{file} vom #{File.mtime(file).strftime '%d.%m.%Y %H:%M'}"
    puts "Bearbeite Dump"
    tmp = Tempfile.new("dump")
    File.foreach(file) do |line|
      tmp << line.gsub(prod_db(application),local_db(application)) 
    end
    tmp.close
    FileUtils.mv(tmp.path,file)
    puts "Loesche Ziel-DB"
    sh "mysql #{mysql_params} -e 'DROP DATABASE IF EXISTS #{local_db(application)};CREATE DATABASE #{local_db(application)};'"
    sh "mysql #{mysql_params} #{local_db(application)} < #{file}"
    puts "fertig!!"
  end

  desc "insert a dump into the local development db"
  task :sync_localdb_to_production => :environment do |t, args|
    file =  "#{Rails.root}/export_dump"
    system "rm #{file}"
    Rake::Task["db:create_dump"].invoke(file)   
   
    puts "Bearbeite Dump"
    tmp = Tempfile.new("dump")
    File.foreach(file) do |line|
      tmp << line.gsub(local_db(application),prod_db(application)) 
    end
    tmp.close    
    FileUtils.mv(tmp.path,file)
    
    system "gzip -c #{file} > #{file}.gz "

    server_dump = "/tmp/dump.gz"
    puts "upload dump"
    sh "scp -C #{file}.gz #{db_config['production']["username"]}@#{host}:#{server_dump}"
    puts "Loesche Ziel-DB"
    sh "ssh #{ssh_user_production}@#{host} \"mysql -u #{db_config['production']["username"]} -p#{db_config['production']["password"]} -h #{db_config['production']["host"] } -e 'DROP DATABASE #{db_config['production']["database"]};CREATE DATABASE #{db_config['production']["database"]}'\""
    puts "import Ziel-DB"
    sh "ssh #{ssh_user_production}@#{host} \"gzip -dc #{server_dump} | mysql -u #{db_config['production']["username"]} -p#{db_config['production']["password"]} -h #{db_config['production']["host"] } #{db_config['production']["database"]} \""
    puts "fertig!!"
  end

  desc "pull down the production db and insert it into the local enviroment db"
  task :sync_production_to_local_db  => :environment do
    Rake::Task["db:download_dump"].invoke
    Rake::Task["db:import_from_file"].invoke(target_dump(application))
    Rake::Task["db:save_dump_file"].invoke
  end
  
  desc "imports then last downloaded dump"
  task :import_last => :environment  do
    Rake::Task["db:import_from_file"].invoke(target_dump(application))
  end
  

  #add as cron:
  ##cd myapp_path/current && RAILS_ENV=production rake db:backup_to_s3 --trace >/dev/null fuer def Fehlermails
  # oder >/dev/null 2>&1 keine mails  
  desc "Backup database to Amazon S3"
  task :backup_to_s3 => :environment do

    require 'aws/s3'  
    raise "S3 ist nicht konfiguriert!" unless config(:s3_key)
   
    begin
      AWS::S3::Base.establish_connection!(
      :access_key_id     => config(:s3_key),
      :secret_access_key =>  config(:s3_secret)
      )
      include AWS::S3
      BUCKET = "deimel-#{application.downcase}"
      Bucket.create(BUCKET)
      puts "BUCKET #{BUCKET}"
  
      backup_file = File.join(backup_path, dump_filename_gz)
  
      Rake::Task["db:create_dump"].invoke(backup_file) 
  
      sh "mysqldump #{mysql_params} #{dump_optins} #{dbname}  | gzip -c > #{backup_file}"
      puts "Created backup: #{backup_file}"
  
      puts "Storing file in S3: #{BUCKET}"
      AWS::S3::S3Object.store(File.basename(backup_file), open(backup_file), BUCKET)
      puts "delete local dump"
      FileUtils.rm backup_file, :verbose => true
      puts "Backup Complete"
    rescue AWS::S3::ResponseError => error
      puts error.response.code.to_s + ": " + error.message
    end
  
  end

end


