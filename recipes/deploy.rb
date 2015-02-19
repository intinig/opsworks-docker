node["deploy"].each do |application, deploy|
  if deploy[:application_type] != 'other' || deploy["environment_variables"]["APP_TYPE"] != 'docker'
    Chef::Log.debug("Skipping deploy::docker application #{application} as it is not deployed to this layer")
    next
  end

  deploy["containers"].each do |c|
    c.each do |app_name, app_config|
      Chef::Log.debug("Evaluating #{app_name}...")
      e = EnvHelper.new app_name, app_config, deploy, node

      image = app_config["image"]
      containers = app_config["containers"] || 1

      environment = e.merged_environment

      Chef::Log.debug("Deploying '#{application}/#{app_name}', from '#{image}'")

      execute "pulling #{image}" do
        Chef::Log.debug("Pulling '#{image}'...")
        command "docker pull #{image}:latest"
        not_if { e.manual? }
      end

      containers.to_i.times do |i|
        ruby_block "waiting" do
          block do
            sleep(app_config["startup_time"].to_i) if app_config["startup_time"] && i > 0
          end
          not_if { e.manual? }
        end

        execute "kill running #{app_name}#{i} container" do
          Chef::Log.info("Killing running #{application}/#{app_name}#{i} container...")
          command "docker kill #{app_name}#{i}"
          only_if { system("docker ps -f status=running | grep ' #{app_name}#{i} '") && e.auto? }
        end

        execute "remove stopped #{app_name}#{i} container" do
          Chef::Log.info("Removing the #{application}/#{app_name}#{i} container...")
          command "docker rm  #{app_name}#{i}"
          only_if "docker ps -af status=exited | grep ' #{app_name}#{i} '"
        end

        execute "migrate #{app_name}#{i} container" do
          Chef::Log.info("Migrating #{app_name}#{i}...")
          command "docker run --rm #{e.env_string(environment)} #{e.links} #{e.volumes} #{e.volumes_from} #{image} #{app_config["migration"]}"
          only_if { e.migrate? && i == 0 && e.auto? }
        end

        execute "launch #{app_name}#{i} container" do
          (history = Mixlib::ShellOut.new "docker history -q #{image} | head -1").run_command
          environment["RELEASE_TAG"] = history.stdout.strip

          Chef::Log.info("Launching #{image}...")
          command "docker run -d -h #{e.hostname i} --name #{app_name}#{i} #{e.ports} #{e.env_string(environment)} #{e.links} #{e.volumes} #{e.volumes_from} #{e.entrypoint} #{image} #{e.cmd i}"
          not_if "docker ps -f status=running | grep ' #{app_name}#{i} '"
        end

        cron "#{app_name}#{i} cron" do
          action :create
          minute e.cron["minute"]
          hour e.cron["hour"]
          weekday e.cron["weekday"]
          command "docker run --rm --name #{app_name}#{i} #{e.env_string(environment)} #{e.links} #{e.volumes} #{e.volumes_from} #{e.entrypoint} #{image} #{app_config["command"]}"
          only_if { e.cron? && i==0 }
        end

      end
    end
  end
end
