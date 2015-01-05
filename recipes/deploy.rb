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

  containers = environment.delete :CONTAINERS
  containers = containers ? containers.to_i : 1
  
  execute "pulling #{application} image" do
    Chef::Log.info("Pulling '#{image}'...")
    command "docker pull #{image}"
  end

  ##
  # @TODO Here what we should actually be doing is spin up a new container
  #       add it to some kind of load balancing haproxy and after we're done
  #       and we're sure it's running we kill it.
  containers.times do |i|
    execute "kill running #{application}#{i} container" do
      Chef::Log.info("Killing running #{application}#{i} containers...")
      command "docker kill #{application}#{i}"
      only_if "docker ps -f status=running | grep ' #{application}#{i} '"
    end
  end

  containers.times do |i|
    execute "remove stopped #{application}#{i} container" do
      Chef::Log.info("Removing the #{application}#{i} container...")
      command "docker rm  #{application}#{i}"
      only_if "docker ps -a | grep ' #{application}#{i} '"
    end
  end

  containers.times do |i|
    execute "launch #{application} container" do
      Chef::Log.info("Launching #{image}...")
      
      { "PG_HOST" => deploy[:database][:host],
        "PG_USER" =>  deploy[:database][:username],
        "PG_PASSWORD" => deploy[:database][:password]
      }.each do |k,v|
        environment[k] = v unless v.nil? || v = ""
      end
      
      env_string = environment.inject("") do |memo, (key, value)|
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

      Chef::Log.info("[DEBUG] #{env_string}")
      Chef::Log.info("[DEBUG] docker run -d --name #{application}#{i} #{ports} #{env_string} #{links} #{volumes_from} #{image}")
      
      command "docker run -d --name #{application}#{i} #{ports} #{env_string} #{links} #{volumes_from} #{image}"
    end
  end
end
