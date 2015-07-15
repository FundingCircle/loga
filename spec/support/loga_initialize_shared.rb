shared_context 'loga initialize' do
  let(:io) { StringIO.new }
  before do
    Loga.reset
    Loga.configure do |config|
      config.service_name    = 'hello_world_app'
      config.service_version = '1.0'
      config.devices         = { type: :io, io: io }
    end
    Loga.initialize!
  end
  let(:json) do
    io.rewind
    JSON.parse(io.read)
  end
end
