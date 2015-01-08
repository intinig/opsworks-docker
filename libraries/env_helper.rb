class EnvHelper
  def initialize app_config
    @app_config = app_config
  end

  def app_config
    @app_config
  end

  def env_string(environment)
    stringify(environment, "--env")
  end

  def volumes
    EnvHelper.stringify app_config["volumes"], "-v"
  end

  def volumes_from
    EnvHelper.stringify app_config["volumes"], "--volumes-from"
  end

  def ports
    EnvHelper.stringify app_config["ports"], "-p"
  end

  def links
    EnvHelper.stringify app_config["links"], "--link"
  end

  def stringify(vals, parameter)
    (vals || []).inject("") do |memo, value|
      memo + "#{parameter} #{value}"
    end
  end
end
