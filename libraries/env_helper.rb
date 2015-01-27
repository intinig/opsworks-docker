class EnvHelper
  attr_reader :app_config, :deploy, :app_name, :node

  def initialize app_name, app_config, deploy, node
    @node = node
    @app_name = app_name
    @app_config = app_config
    @deploy = deploy
  end

  def retrieve container
    if container
      deploy["containers"].find {|cnt| cnt.keys.first  == container}[container]["env"]
    else
      {}
    end
  end

  def merged_environment
    retrieve(app_config["env_from"]).merge(app_config["env"] || {})
  end

  def env_string environment
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

  def hostname container_id
    if app_config["hostname"] == "opsworks"
      hostname = node["opsworks"]["stack"]["name"] +
                 " " +
                 node["opsworks"]["instance"]["hostname"]

      hostname = hostname.downcase.gsub(" ", "-")
    else
      hostname = "#{app_name}#{container_id}." + node["opsworks"]["instance"]["hostname"]
    end

    hostname
  end

  def cron
    cron_data = app_config["cron"] || {}

    {
      "minute"  => cron_data["minute"]  || "*",
      "hour"    => cron_data["hour"]    || "*",
      "weekday" => cron_data["weekday"] || "*"
    }
  end

  def deploy_level
    return "auto" if node["manual"] && node["manual"].include?(app_name)
    app_config["deploy"]
  end

  def manual?
    check_deploy_level "manual"
  end

  def auto?
    check_deploy_level "auto"
  end

  def cron?
    check_deploy_level "cron"
  end

  def check_deploy_level lvl
    deploy_level == lvl
  end

  def migrate?
    auto? && app_config["migration"]
  end

  def cmd container_id
    app_config["command"].to_s.gsub("${app_name}", "#{app_name}#{container_id}")
  end

  def entrypoint
    if app_config["entrypoint"]
      "--entrypoint=\"#{app_config['entrypoint']}\""
    else
      ""
    end
  end
end
