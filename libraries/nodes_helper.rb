module NodesHelper
  def self.special_node node
    node[:opsworks][:layers]['docker'][:instances].keys.sort.first
  end
end
