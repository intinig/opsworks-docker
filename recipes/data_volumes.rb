node["deploy"].each do |application, deploy|
  if deploy["application_type"] != 'other' || deploy["environment_variables"]["APP_TYPE"] != 'docker'
    Chef::Log.debug("Skipping deploy::docker application #{application} as it is not deployed to this layer")
    next
  end

  deploy["data_volumes"].each do |c|
    c.each do |app_name, app_config|
      e = EnvHelper.new app_name, app_config, deploy, node

      execute "launch #{app_name} data only container" do
        Chef::Log.info("Launching busybox for #{app_name}...")
        command "docker run --name #{app_name} #{e.volumes} busybox"
        not_if "docker ps -a | grep #{app_name}"
      end
    end
  end
end
