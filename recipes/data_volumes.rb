node[:deploy].each do |application, deploy|
  if deploy[:application_type] != 'other' || deploy["environment_variables"]["APP_TYPE"] != 'docker'
    Chef::Log.debug("Skipping deploy::docker application #{application} as it is not deployed to this layer")
    next
  end

  deploy["data_volumes"].each do |c|
    c.each do |app_name, app_config|
      Chef::Log.debug("Evaluating #{app_name}...")
      e = EnvHelper.new app_name, app_config, deploy, node

      image = "busybox"

      Chef::Log.debug("Deploying '#{application}/#{app_name}', from '#{image}'")

      ruby_block "waiting" do
        block do
          sleep(app_config["startup_time"].to_i) if app_config["startup_time"] && i > 0
        end
      end

      execute "launch #{app_name} container" do
        Chef::Log.info("Launching #{image}...")
        command "docker run -h #{app_name} --name #{app_name} #{e.volumes} #{image}"
      end
    end
  end
end
