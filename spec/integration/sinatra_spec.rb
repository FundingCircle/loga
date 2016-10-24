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

  context 'when RACK_ENV is production', if: ENV['RACK_ENV'].eql?('development') do
    let(:format) { :simple }
    let(:last_log_entry) do
      io.rewind
      io.read
    end

    context 'get request' do
      it 'logs the request' do
        get '/ok', username: 'yoshi'
        expect(last_log_entry)
          .to eq("#{time_anchor.iso8601(3)} GET /ok?username=yoshi 200 in 0ms\n")
      end
    end

    context 'request with redirect' do
      it 'specifies the original path' do
        get '/new'
        expect(last_log_entry).to eql("#{time_anchor.iso8601(3)} GET /new 302 in 0ms\n")
      end
    end

    context 'when the request raises an exception' do
      let(:log_entry_match) do
        %r{GET /error 500 in 0ms.undefined method `name' for nil:NilClass..+sinatra_spec}m
      end

      it 'logs the request with the exception' do
        get '/error'
        expect(last_log_entry).to match(log_entry_match)
      end
    end
  end
end
