# Required attributes at the node["docker"]["exec"] level: "container", "command"

execute "Docker Exec" do
  command "docker exec #{node["docker"]["exec"]["container"]} #{node["docker"]["exec"]["command"]}"
  only_if {node["docker"] && node["docker"]["exec"]}
end
