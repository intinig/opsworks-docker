# Expects the following json structure
# { "docker" : { "registry_0": { "username": "foo", "password": "bar"}}}

if node["docker"]
  node["docker"]["registries"].each do |registry, credentials|
    execute "docker login #{registry}" do
      command "docker login -e='.' -u='#{credentials["username"]}' -p='#{credentials["password"]}' #{registry}"
    end
  end
end
