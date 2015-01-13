execute "cleaning up all unused images" do
  Chef::Log.info("Cleaning up unused images...")
  command "docker rmi `docker images -q -f dangling=true`"
end
