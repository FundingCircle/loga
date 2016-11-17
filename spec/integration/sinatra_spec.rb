require 'spec_helper'

RSpec.describe 'Structured logging with Sinatra', timecop: true do
  let(:io) { StringIO.new }
  let(:format) {}
  before do
    Loga.reset
    Loga.configure(
      device: io,
      filter_parameters: [:password],
      format: format,
      service_name: 'hello_world_app',
      service_version: '1.0',
      tags: [:uuid, 'TEST_TAG'],
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
      use Loga::Rack::Logger

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

  context 'when RACK_ENV is production', if: ENV['RACK_ENV'].eql?('production') do
    let(:format) { :gelf }
    include_examples 'request logger'

    it 'does not include the controller name and action' do
      get '/ok'
      expect(last_log_entry).to_not include('_request.controller')
    end
  end

  # rubocop:disable Metrics/LineLength
  context 'when RACK_ENV is development', if: ENV['RACK_ENV'].eql?('development') do
    let(:format) { :simple }
    let(:last_log_entry) do
      io.rewind
      io.read
    end
    let(:data) do
      {
        'status' => 200,
        'method' => 'GET',
        'path'   => '/ok',
        'params' => { 'username'=>'yoshi' },
        'request_id' => '700a6a01',
        'request_ip' => '127.0.0.1',
        'user_agent' => nil,
        'duration'   => 0,
      }
    end
    let(:data_as_text)  { "data=#{{ request: data }.inspect}" }
    let(:time_pid_tags) { '[2015-12-15T09:30:05.123000+06:00 #999][700a6a01 TEST_TAG]' }

    before do
      allow(Process).to receive(:pid).and_return(999)
    end

    context 'get request' do
      it 'logs the request' do
        get '/ok', { username: 'yoshi' }, 'HTTP_X_REQUEST_ID' => '700a6a01'

        expect(last_log_entry).to eq("I, #{time_pid_tags} GET /ok?username=yoshi 200 in 0ms type=request #{data_as_text}\n")
      end
    end

    context 'request with redirect' do
      let(:data) do
        super().merge(
          'status' => 302,
          'path'   => '/new',
          'params' => {},
        )
      end
      it 'specifies the original path' do
        get '/new', {}, 'HTTP_X_REQUEST_ID' => '700a6a01'
        expect(last_log_entry).to eql("I, #{time_pid_tags} GET /new 302 in 0ms type=request #{data_as_text}\n")
      end
    end

    context 'when the request raises an exception' do
      let(:data) do
        super().merge(
          'status' => 500,
          'path'   => '/error',
          'params' => {},
        )
      end

      it 'logs the request with the exception' do
        get '/error', {}, 'HTTP_X_REQUEST_ID' => '700a6a01'
        expect(last_log_entry).to eql("E, #{time_pid_tags} GET /error 500 in 0ms type=request #{data_as_text} exception=undefined method `name' for nil:NilClass\n")
      end
    end
  end
  # rubocop:enable Metrics/LineLength
end
