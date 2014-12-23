node[:deploy].each do |application, deploy|

  # node[:deploy]['appshortname'][:environment_variables][:variable_name]

  if deploy[:application_type] != 'other'
    Chef::Log.debug("Skipping deploy::docker application #{application} as it is not deployed to this layer")
    next
  elsif deploy[:environment_variables][:APP_TYPE] != 'docker'
    Chef::Log.debug("Skipping deploy::docker application #{application} as it is not of type 'docker'")
    next
  end

  image = deploy[:environment_variables][:IMAGE]
  Chef::Log.debug("Going to deploy '#{application}', from '#{image}'")


  execute "pulling #{application} image" do
    Chef::Log.info("Pulling '#{image}'...")
    command "docker pull #{image}"
  end

  execute "kill running #{application} container" do
    Chef::Log.info("Killing running #{application} containers...")
    command "docker kill #{application}"
    only_if "docker ps | grep ' #{application} '"
  end

  execute "remove stopped #{application} container" do
    Chef::Log.info("Removing the #{application} container...")
    command "docker rm  #{application}"
    only_if "docker ps -a | grep ' #{application} '"
  end

  execute "launch #{application} container" do
    Chef::Log.info("Launching #{image}...")

    env_vars = {
      "PG_HOST" => deploy[:database][:host],
      "PG_USER" =>  deploy[:database][:username],
      "PG_PASSWORD" => deploy[:database][:password]
    }

    env_string = env_vars.inject("") do |memo, (key, value)|
      memo + "--env \"#{key}=#{value}\" "
    end

    command "docker run -d --name #{application} #{env_string} #{image}"
  end
end
