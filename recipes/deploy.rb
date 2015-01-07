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
      next unless app_config["deploy"] == "auto" || (node["manual"] && node["manual"].include?(app_name))
      image = app_config["image"]

      containers = app_config["containers"] || 1

      environment = (app_config["env"] || {}).dup
      volumes = app_config["volumes"] || []
      cmd = app_config["command"]
      volumes_from = app_config["volumes_from"] || []
      ports = app_config["ports"] || []
      links = app_config["links"] || []
      hostname = node[:opsworks][:stack][:name] + " " + node[:opsworks][:instance][:hostname] if app_config["hostname"] == "opsworks"

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

      env_string = environment.inject("") do |memo, (key, value)|
        memo + "--env \"#{key}=#{value}\" "
      end

      volumes = volumes.inject("") do |memo, value|
        memo + "-v #{value} "
      end

      volumes_from = volumes_from.inject("") do |memo, value|
        memo + "--volumes-from #{value} "
      end

      ports = ports.inject("") do |memo, value|
        memo + "-p #{value} "
      end

      links = links.inject("") do |memo, value|
        memo + "--link #{value} "
      end

      Chef::Log.debug("Deploying '#{application}/#{app_name}', from '#{image}'")

      execute "pulling #{image}" do
        Chef::Log.info("Pulling '#{image}'...")
        command "docker pull #{image}"
      end

      ##
      # @TODO Here what we should actually be doing is spin up a new container
      #       add it to some kind of load balancing haproxy and after we're done
      #       and we're sure it's running we kill it.
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

          command "docker run -d -h #{hostname} --name #{app_name}#{i} #{ports} #{env_string} #{links} #{volumes} #{volumes_from} #{image} #{cmd}"
        end
      end
    end
  end
end
