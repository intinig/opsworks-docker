node[:deploy].each do |application, deploy|

  # node[:deploy]['appshortname'][:environment_variables][:variable_name]

  environment = deploy[:environment_variables].dup

  if deploy[:application_type] != 'other'
    Chef::Log.debug("Skipping deploy::docker application #{application} as it is not deployed to this layer")
    next
  elsif environment.delete(:APP_TYPE) != 'docker'
    Chef::Log.debug("Skipping deploy::docker application #{application} as it is not of type 'docker'")
    next
  end

  image = environment.delete :IMAGE
  Chef::Log.debug("Going to deploy '#{application}', from '#{image}'")


  execute "pulling #{application} image" do
    Chef::Log.info("Pulling '#{image}'...")
    command "docker pull #{image}"
  end

  execute "kill running #{application} container" do
    Chef::Log.info("Killing running #{application} containers...")
    command "docker kill #{application}"
    only_if "docker ps -f status=running | grep ' #{application} '"
  end

  execute "remove stopped #{application} container" do
    Chef::Log.info("Removing the #{application} container...")
    command "docker rm  #{application}"
    only_if "docker ps -a | grep ' #{application} '"
  end

  execute "launch #{application} container" do
    Chef::Log.info("Launching #{image}...")

    env_vars = environment
    env_vars.merge!({
      "PG_HOST" => deploy[:database][:host],
      "PG_USER" =>  deploy[:database][:username],
      "PG_PASSWORD" => deploy[:database][:password]
    }) if deploy[:database]

    env_string = env_vars.inject("") do |memo, (key, value)|
      memo + "--env \"#{key}=#{value}\" "
    end

    volumes_from = deploy["volumes_from"].inject("") do |memo, value|
      memo + "--volumes-from #{value} "
    end if deploy["volumes_from"]

    ports = deploy["ports"].inject("") do |memo, value|
      memo + "-p #{value} "
    end if deploy["ports"]

    links = deploy["links"].inject("") do |memo, value|
      memo + "--link #{value} "
    end if deploy["links"]
    
    command "docker run -d --name #{application} #{ports} #{env_string} #{volumes_from} #{image}"
  end
end
