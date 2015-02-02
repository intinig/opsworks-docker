# Warning: It assumes you're using Amazon Linux
# Does not support any other platform but extending it
# is trivial.

package "docker-io" do
  action :install
end

service "docker" do
  action :start
end
