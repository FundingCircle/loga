require 'spec_helper'
require 'timecop'
require 'action_controller/railtie'

ENV['RAILS_ENV'] = 'production'
module RailsApp
  class Application < Rails::Application
    config.secret_key_base = '572c86f5ede338bd8aba8dae0fd3a326aabababc98d1e6ce34b9f5'

    routes.draw do
      get '/ok'    => 'rails_app/static#ok'
      get '/error' => 'rails_app/static#error'
    end
  end

  class StaticController < ActionController::Base
    def ok
      render text: 'Hello Rails'
    end

    def error
      fail StandardError, 'Hello Rails Error'
    end
  end
end

RailsApp::Application.configure do |config|
  config.middleware.insert_before Rails::Rack::Logger,
                                  Loga::Rack::Logger
end

describe 'Rack request logger with Rails', timecop: true do
  include_context 'loga initialize'

  before do
    allow(Rails).to receive(:logger).and_return(Logger.new(StringIO.new))
  end

  let(:app)    { RailsApp::Application }

  context 'when the request is successful' do
    it 'logs the request' do
      get '/ok',
          { username: 'yoshi' },
          'HTTP_USER_AGENT' => 'Chrome', 'HTTP_X_REQUEST_ID' => '471a34dc'
      expect(json).to match(
        '@version'   => '1',
        'host'       => 'bird.example.com',
        'message'    => 'GET /ok?username=yoshi',
        '@timestamp' => '2015-12-15T03:30:05.123Z',
        'severity'   => 'INFO',
        'type'       => 'request',
        'service'    => {
          'name' => 'hello_world_app',
          'version' => '1.0',
        },
        'event' => {
          'method' => 'GET',
          'path'   => '/ok',
          'params' => {
            'username' => 'yoshi',
          },
          'request_id' => '471a34dc',
          'request_ip' => '127.0.0.1',
          'user_agent' => 'Chrome',
          'status'     => 200,
          'duration'   => 0,
        },
        'tags' => [],
      )
    end
  end

  context 'when the request raises an exception' do
    it 'logs the request with the exception' do
      get '/error',
          { username: 'yoshi' },
          'HTTP_USER_AGENT' => 'Chrome', 'HTTP_X_REQUEST_ID' => '471a34dc'

      expect(json).to match(
        '@version'   => '1',
        'host'       => 'bird.example.com',
        'message'    => 'GET /error?username=yoshi',
        '@timestamp' => '2015-12-15T03:30:05.123Z',
        'severity'   => 'ERROR',
        'type'       => 'request',
        'service'    => {
          'name' => 'hello_world_app',
          'version' => '1.0',
        },
        'event' => {
          'method' => 'GET',
          'path'   => '/error',
          'params' => {
            'username' => 'yoshi',
          },
          'request_id' => '471a34dc',
          'request_ip' => '127.0.0.1',
          'user_agent' => 'Chrome',
          'status'     => 500,
          'duration'   => 0,
        },
        'exception' => {
          'klass' => 'StandardError',
          'message' => 'Hello Rails Error',
          'backtrace' => be_a(Array),
        },
        'tags' => [],
      )
    end
  end
end
