include_recipe 'deploy'

node[:deploy].each do |application, deploy|

  # node[:deploy]['appshortname'][:environment_variables][:variable_name]

  if deploy[:application_type] != 'other'
    Chef::Log.debug("Skipping application #{application} as it is not deployed to this layer")
    next
  elsif deploy[:environment_variables][:APP_TYPE] != 'docker'
    Chef::Log.debug("Skipping application #{application} as it is not of type 'docker'")
    next
  elsif node[:migrate] != "true"
    next
  end

  image = deploy[:environment_variables][:IMAGE]
  Chef::Log.debug("Going to migrate '#{application}', from '#{image}'")

  
  execute "migrating #{application} container" do
    Chef::Log.info("Migrating #{application} from  #{image}...")

    env_vars = {
      "PG_HOST" => deploy[:database][:host],
      "PG_USER" =>  deploy[:database][:username],
      "PG_PASSWORD" => deploy[:database][:password]
    }

    env_string = env_vars.inject("") do |memo, (key, value)|
      memo + "--env \"#{key}=#{value}\" "
    end

    command "docker run --rm #{env_string} #{image} bundle exec rake db:migrate"
  end
end
