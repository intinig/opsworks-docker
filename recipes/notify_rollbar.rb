node["deploy"].each do |application, deploy|
  if deploy[:application_type] != 'other' || deploy["environment_variables"]["APP_TYPE"] != 'docker'
    Chef::Log.debug("Skipping application #{application} as it is not deployed to this layer")
    next
  end

  deploy["containers"].each do |c|
    c.each do |app_name, app_config|
      if app_config["notifications"] && app_config["notifications"]["rollbar"]
        execute "notifying rollbar of #{app_name} deployment" do
          access_token = app_config["notifications"]["rollbar"]["access_token"]
          env_var = app_config["notifications"]["rollbar"]["env_var"]
          rev_var = app_config["notifications"]["rollbar"]["rev_var"]
          cmd = "docker exec #{app_name}0 sh -c 'curl https://api.rollbar.com/api/1/deploy/ -F access_token=#{access_token} -F environment=$#{env_var} -F revision=$#{rev_var} -F local_username=#{deploy["user"]}'"

          Chef::Log.info("Notifying rollbar with command `#{cmd}`")
          command cmd
        end
      end
    end
  end
end
