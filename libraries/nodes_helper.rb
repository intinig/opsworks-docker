module NodesHelper
  def special_node
    instances = node[:opsworks][:layers]['docker'][:instances]
    selected_node = instances.keys.sort.first
    instances[selected_node]
  end
end
