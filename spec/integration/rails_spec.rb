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

  let(:app) { RailsApp::Application }

  context 'when the request is successful' do
    it 'logs the request' do
      get '/ok',
          { username: 'yoshi' },
          'HTTP_USER_AGENT' => 'Chrome', 'HTTP_X_REQUEST_ID' => '471a34dc'

      expect(json).to match(
        'version'             => '1.1',
        'host'                => 'bird.example.com',
        'short_message'       => 'GET /ok?username=yoshi',
        'timestamp'           => 1_450_150_205.123,
        'level'               => 6,
        '_type'               => 'request',
        '_service.name'       => 'hello_world_app',
        '_service.version'    => '1.0',
        '_request.method'     => 'GET',
        '_request.path'       => '/ok',
        '_request.params'     => { 'username' => 'yoshi' },
        '_request.request_ip' => '127.0.0.1',
        '_request.user_agent' => 'Chrome',
        '_request.status'     => 200,
        '_request.request_id' => '471a34dc',
        '_request.duration'   => 0,
        '_tags'               => [],
      )
    end
  end

  context 'when the request raises an exception' do
    it 'logs the request with the exception' do
      get '/error',
          { username: 'yoshi' },
          'HTTP_USER_AGENT' => 'Chrome', 'HTTP_X_REQUEST_ID' => '471a34dc'

      expect(json).to match(
        'version'              => '1.1',
        'host'                 => 'bird.example.com',
        'short_message'        => 'GET /error?username=yoshi',
        'timestamp'            => 1_450_150_205.123,
        'level'                => 3,
        '_type'                => 'request',
        '_service.name'        => 'hello_world_app',
        '_service.version'     => '1.0',
        '_request.method'      => 'GET',
        '_request.path'        => '/error',
        '_request.params'      => { 'username' => 'yoshi' },
        '_request.request_ip'  => '127.0.0.1',
        '_request.user_agent'  => 'Chrome',
        '_request.status'      => 500,
        '_request.request_id'  => '471a34dc',
        '_request.duration'    => 0,
        '_exception.klass'     => 'StandardError',
        '_exception.message'   => 'Hello Rails Error',
        '_exception.backtrace' => be_a(String),
        '_tags'               => [],
      )
    end
  end
end
