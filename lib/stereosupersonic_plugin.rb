# StereosupersonicPlugin

%w{  helpers views}.each do |dir|
  path = File.join(File.dirname(__FILE__), 'app', dir)
  if File.exists?(path)
    Dir.glob(path + "/*.rb").each do |f|
      require path + "/" + File.basename(f, ".rb")
    end
  end
end


%w{ models controllers }.each do |dir|
  path = File.join(File.dirname(__FILE__), 'app', dir)
  $LOAD_PATH << path
  ActiveSupport::Dependencies.autoload_paths << path
  ActiveSupport::Dependencies.autoload_once_paths.delete(path)
end
