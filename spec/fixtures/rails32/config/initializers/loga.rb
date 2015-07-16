STREAM = StringIO.new

Loga.configure do |config|
  config.service_name    = 'hello_world_app'
  config.service_version = '1.0'
  config.device          = STREAM
end

Loga.initialize!
