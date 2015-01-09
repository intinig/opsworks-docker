class EnvHelper
  def initialize app_config, node
    @app_config = app_config
    @node = node
  end

  def app_config
    @app_config
  end

  def node
    @node
  end

  def env_string(environment, deploy)
    if app_config["database"]
      {
        "DB_ADAPTER" => deploy[:database][:adapter],
        "DB_DATABASE" => deploy[:database][:database],
        "DB_HOST" => deploy[:database][:host],
        "DB_PASSWORD" => deploy[:database][:password],
        "DB_PORT" => deploy[:database][:port],
        "DB_RECONNECT" => deploy[:database][:reconnect],
        "DB_USERNAME" =>  deploy[:database][:username],
      }.each do |k,v|
        environment[k] = v
      end
    end

    environment["RELEASE_TAG"] = node[app_config["image"]]

    Chef::Log.info "[DEBUG] our pre-string env is #{environment.inspect}"

    stringify_hash(environment, "--env")
  end

  def volumes
    stringify app_config["volumes"], "-v"
  end

  def volumes_from
    stringify app_config["volumes_from"], "--volumes-from"
  end

  def ports
    stringify app_config["ports"], "-p"
  end

  def links
    stringify app_config["links"], "--link"
  end

  def stringify(vals, parameter)
    (vals || []).inject("") do |memo, value|
      memo + "#{parameter} #{value} "
    end
  end

  def stringify_hash(vals, parameter)
    memo = ""
    (vals || {}).each do |key, val|
      memo += "#{parameter} '#{key}=#{val}' "
    end

    memo
  end
end
