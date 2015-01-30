logrotate_app 'docker' do
  cookbook  'logrotate'
  path      '/var/lib/docker/containers/*/*.log'
  frequency 'daily'
  rotate    7
  options   ['compress', 'delaycompress', 'copytruncate', 'sharedscripts']
  postrotate "/usr/bin/docker restart #{node["logrotate"]["forwarder"]}"
end
