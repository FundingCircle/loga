require 'spec_helper'

Loga::MySinatraApp = Class.new(Sinatra::Base) do
  set :logging, false

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

  get '/attach_context' do
    Loga.attach_context(fruit: 'banana')

    'I am a banana'
  end
end

RSpec.describe 'Structured logging with Sinatra', :with_hostname, :timecop do
  let(:device) { StringIO.new }

  let(:last_log_entry) do
    device.rewind
    JSON.parse(device.read)
  end

  let(:app) do
    Rack::Builder.new do
      use Loga::Rack::RequestId
      use Loga::Rack::Logger
      run Loga::MySinatraApp
    end
  end

  before do
    Loga.reset

    Loga.configure(
      device: device,
      filter_parameters: [:password],
      format: format,
      service_name: 'hello_world_app',
      service_version: '1.0',
      tags: [:uuid, 'TEST_TAG'],
    )
  end

  describe 'RACK_ENV is production', if: ENV['RACK_ENV'].eql?('production') do
    let(:format) { :gelf }

    include_examples 'request logger'

    it 'attaches a custom context' do
      get '/attach_context'

      expect(last_log_entry['_fruit']).to eq 'banana'
    end

    it 'does not include the controller name and action' do
      get '/ok'

      expect(last_log_entry).not_to include('_request.controller')
    end
  end

  describe 'RACK_ENV is development', if: ENV['RACK_ENV'].eql?('development') do
    let(:format) { :simple }

    let(:last_log_entry) do
      device.rewind
      device.read
    end

    let(:time_pid_tags) { '[2015-12-15T09:30:05.123000+06:00 #999][700a6a01 TEST_TAG]' }

    before { allow(Process).to receive(:pid).and_return(999) }

    context 'when request responds with HTTP status 200' do
      let(:data) do
        {
          request: {
            'status' => 200,
            'method' => 'GET',
            'path'   => '/ok',
            'params' => { 'username'=>'yoshi' },
            'request_id' => '700a6a01',
            'request_ip' => '127.0.0.1',
            'user_agent' => nil,
            'duration'   => 0,
          },
        }
      end

      it 'logs the request' do
        get '/ok', { username: 'yoshi' }, 'HTTP_X_REQUEST_ID' => '700a6a01'

        result = "I, #{time_pid_tags} GET /ok?username=yoshi "\
                 "200 in 0ms type=request data=#{data.inspect}\n"

        expect(last_log_entry).to eq(result)
      end
    end

    context 'when request responds with HTTP status 302' do
      let(:data) do
        {
          request: {
            'status' => 302,
            'method' => 'GET',
            'path'   => '/new',
            'params' => {},
            'request_id' => '700a6a01',
            'request_ip' => '127.0.0.1',
            'user_agent' => nil,
            'duration'   => 0,
          },
        }
      end

      it 'logs the request' do
        get '/new', {}, 'HTTP_X_REQUEST_ID' => '700a6a01'

        result = "I, #{time_pid_tags} GET /new 302 "\
                 "in 0ms type=request data=#{data.inspect}\n"

        expect(last_log_entry).to eql(result)
      end
    end

    context 'when the request responds with HTTP status 500' do
      let(:data) do
        {
          request: {
            'status' => 500,
            'method' => 'GET',
            'path'   => '/error',
            'params' => {},
            'request_id' => '700a6a01',
            'request_ip' => '127.0.0.1',
            'user_agent' => nil,
            'duration'   => 0,
          },
        }
      end

      it 'logs the request' do
        get '/error', {}, 'HTTP_X_REQUEST_ID' => '700a6a01'

        result = "E, #{time_pid_tags} GET /error 500 "\
                 "in 0ms type=request data=#{data.inspect} "\
                 "exception=undefined method `name' for nil:NilClass\n"

        expect(last_log_entry).to eql(result)
      end
    end
  end
end
