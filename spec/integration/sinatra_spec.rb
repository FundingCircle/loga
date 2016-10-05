require 'spec_helper'

RSpec.describe 'Structured logging with Sinatra', timecop: true do
  let(:io) { StringIO.new }
  before do
    Loga.reset
    Loga.configure(
      device: io,
      filter_parameters: [:password],
      format: :gelf,
      service_name: 'hello_world_app',
      service_version: '1.0',
    )
  end
  let(:last_log_entry) do
    io.rewind
    JSON.parse(io.read)
  end

  let(:app) do
    Class.new(Sinatra::Base) do
      # Disable show_exceptions and rely on user defined exception handlers
      # (e.i. the error blocks)
      set :show_exceptions, false

      use Loga::Rack::RequestId
      use Loga::Rack::Logger, nil, [:uuid, 'TEST_TAG']

      error do
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

  it 'does not include the controller name and action' do
    get '/ok'
    expect(last_log_entry).to_not include('_request.controller')
  end
end
