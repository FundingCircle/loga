require 'spec_helper'

describe 'Rack request logger with Sinatra', timecop: true do
  let(:io) { StringIO.new }
  before do
    Loga.reset
    Loga.configure do |config|
      config.service_name      = 'hello_world_app'
      config.service_version   = '1.0'
      config.filter_parameters = [:password]
      config.device            = io
    end
    Loga.initialize!
  end
  let(:json) do
    io.rewind
    JSON.parse(io.read)
  end

  let(:app) do
    Class.new(Sinatra::Base) do
      set :environment, :production
      use Loga::Rack::RequestId
      use Loga::Rack::Logger, Loga.logger, [:uuid]

      error StandardError do
        status 500
        body 'Ooops'
      end

      get '/ok' do
        'Hello Sinatra'
      end

      get '/error' do
        nil.name
      end

      post '/users' do
        content_type :json
        params.to_json
      end

      get '/new' do
        redirect '/ok'
      end
    end
  end

  include_examples 'request logger'
end
