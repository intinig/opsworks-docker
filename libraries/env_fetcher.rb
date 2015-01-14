module EnvFetcher
  def self.retrieve container, deploy
    if container
      deploy["containers"].find {|cnt| cnt.keys.first == container}[container]["env"]
    else
      {}
    end
  end

  def self.merged_environment app_config, deploy
    self.retrieve(app_config["env_from"], deploy).merge(app_config["env"] || {})
  end
end
