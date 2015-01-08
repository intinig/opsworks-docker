include EnvHelper

node[:deploy].each do |application, deploy|
  if deploy[:application_type] != 'other'
    Chef::Log.debug("Skipping deploy::docker application #{application} as it is not deployed to this layer")
    next
  elsif deploy["environment_variables"]["APP_TYPE"] != 'docker'
    Chef::Log.debug("Skipping deploy::docker application #{application} as it is not of type 'docker'")
    next
  end

  deploy["containers"].each do |c|
    c.each do |app_name, app_config|
      Chef::Log.info("Evaluating #{app_name}...")
      next unless app_config["deploy"] == "auto" || (node["manual"] && node["manual"].include?(app_name))

      image = app_config["image"]
      containers = app_config["containers"] || 1
      environment = (app_config["env"] || {}).dup

      if app_config["hostname"] == "opsworks"
        hostname = node[:opsworks][:stack][:name] + " " + node[:opsworks][:instance][:hostname]
        hostname = hostname.downcase.gsub(" ", "-")
      end

      if app_config["database"]
        {
          "DB_ADAPTER" => deploy[:database][:adapter],
          "DB_DATABASE" => deploy[:database][:database],
          "DB_HOST" => deploy[:database][:host],
          "DB_PASSWORD" => deploy[:database][:password],
          "DB_PORT" => deploy[:database][:port],
          "DB_RECONNECT" => deploy[:database][:reconnect],
          "DB_USERNAME" =>  deploy[:database][:username]
        }.each do |k,v|
          environment[k] = v
        end
      end

      e = EnvHelper.new app_config

      Chef::Log.debug("Deploying '#{application}/#{app_name}', from '#{image}'")

      execute "pulling #{image}" do
        Chef::Log.info("Pulling '#{image}'...")
        command "docker pull #{image}:latest"
      end

      ruby_block "adding #{image} id to environment" do
        block do
          tag = `docker history -q #{image} | head -1`.strip
          Chef::Log.info("[DEBUG] #{image}:#{tag}")
          environment["RELEASE_TAG"] = tag
        end
      end

      containers.times do |i|
        execute "kill running #{app_name}#{i} container" do
          Chef::Log.info("Killing running #{application}/#{app_name}#{i} container...")
          command "docker kill #{app_name}#{i}"
          only_if "docker ps -f status=running | grep ' #{app_name}#{i} '"
        end

        execute "remove stopped #{app_name}#{i} container" do
          Chef::Log.info("Removing the #{application}/#{app_name}#{i} container...")
          command "docker rm  #{app_name}#{i}"
          only_if "docker ps -a | grep ' #{app_name}#{i} '"
        end

        execute "launch #{app_name}#{i} container" do
          hostname ||= "#{app_name}#{i}"

          Chef::Log.info("Launching #{image}...")

          command "docker run -d -h #{hostname} --name #{app_name}#{i} #{e.ports} #{e.env_string(environment)} #{e.links} #{e.volumes} #{e.volumes_from} #{image} #{app_config["command"]}"
        end
      end
    end
  end
end
