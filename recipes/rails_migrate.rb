include_recipe 'deploy'

node[:deploy].each do |application, deploy|

  if deploy[:application_type] != 'other'
    Chef::Log.debug("Skipping application #{application} as it is not deployed to this layer")
    next
  elsif deploy[:environment_variables][:APP_TYPE] != 'docker'
    Chef::Log.debug("Skipping application #{application} as it is not of type 'docker'")
    next
  elsif node[:migrate] != true
    next
  end

  migrations = node[:migrate] || []

  deploy["containers"].each do |c|
    c.each do |app_name, app_config|
      next unless migrations.include? app_name
    end

    image = app_config["image"]

    containers = app_config["containers"] || 1

    environment = (app_config["env"] || {}).dup
    volumes_from = app_config["volumes_from"] || []
    ports = app_config["ports"] || []
    links = app_config["links"] || []

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

    volumes_from = volumes_from.inject("") do |memo, value|
      memo + "--volumes-from #{value} "
    end

    links = links.inject("") do |memo, value|
      memo + "--link #{value} "
    end

    execute "migrating #{application}/#{app_name} container" do
    Chef::Log.info("Migrating #{application}/#{app_name} from #{image}...")

    command "docker run --rm #{env_string} #{links} #{volumes_from} #{image} bundle exec rake db:migrate"
  end

  end

end
