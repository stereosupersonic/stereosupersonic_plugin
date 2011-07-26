class SonicLogger < Logger

   cattr_accessor :songlog_logger
   
  def self.logger
     songlog_logger ||= create_logger
     songlog_logger
  end
  
  def self.build_log_filename
    file_postfix ||= self.name.underscore.gsub(/_logger/,'').dasherize
    File.join("#{Rails.root}",'log',"#{Rails.env}-#{file_postfix}.log")
  end
  
  def self.log_file
    logfile = File.open(build_log_filename, 'a')
    logfile.sync = true
    logfile
  end
  
  def self.create_logger             
    logger = Logger.new(log_file)
    logger.formatter = proc { |severity, timestamp, progname, msg|"#{timestamp.to_formatted_s(:db)} #{severity} #{msg}\n"}
    logger 
  end

  def self.debug(msg)
    logger.add(Logger::DEBUG) { msg }
  end

  def self.info(msg)
    logger.add(Logger::INFO) { msg }
  end
    
  def self.warn(msg)
    logger.add(Logger::WARN) { msg }
  end  

  def self.error(msg)
    logger.add(Logger::ERROR) { msg }
  end

  def self.fatal(msg)
    logger.add(Logger::FATAL)  { msg }
  end

end