node["deploy"].each do |application, deploy|
  if deploy[:application_type] != 'other' || deploy["environment_variables"]["APP_TYPE"] != 'docker'
    Chef::Log.debug("Skipping docker::cron application #{application} as it is not deployed to this layer")
    next
  end

  deploy["containers"].each do |c|
    c.each do |app_name, app_config|
      Chef::Log.debug("Evaluating #{app_name}...")
      e = EnvHelper.new app_name, app_config, deploy, node

      image = app_config["image"]
      tag = app_config["tag"] ? app_config["tag"] : "latest"

      environment = e.merged_environment

      next unless e.cron?

      Chef::Log.debug("Cron '#{application}/#{app_name}', from '#{image}'")

      execute "pulling #{image}" do
        Chef::Log.debug("Pulling '#{image}'...")
        command "docker pull #{image}:#{tag}"
        only_if { e.cron? }
      end

      cron "#{app_name} cron" do
        action :create
        minute e.cron["minute"]
        hour e.cron["hour"]
        weekday e.cron["weekday"]
        command "docker run --rm #{e.env_string(environment)} #{e.links} #{e.volumes} #{e.volumes_from} #{e.entrypoint} #{image}:#{tag} #{app_config["command"]}"
        only_if { e.cron? }
      end
    end
  end
end
