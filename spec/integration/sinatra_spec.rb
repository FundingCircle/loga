require 'spec_helper'
require 'timecop'
require 'sinatra'

describe 'Rack request logger with Sinatra', timecop: true do
  include_context 'loga initialize'

  let(:app) do
    Class.new(Sinatra::Base) do
      set :environment, :production
      use Loga::Rack::RequestId
      use Loga::Rack::Logger

      error StandardError do
        status 500
        body 'Ooops'
      end

      get '/ok' do
        'Hello Sinatra'
      end

      get '/error' do
        fail StandardError, 'Hello Sinatra Error'
      end
    end
  end

  context 'when environment is production' do
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
            'request_ip' => '127.0.0.1',
            'user_agent' => 'Chrome',
            'status'     => 200,
            'request_id' => '471a34dc',
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
            'request_ip' => '127.0.0.1',
            'user_agent' => 'Chrome',
            'status'     => 500,
            'request_id' => '471a34dc',
            'duration'   => 0,
          },
          'exception' => {
            'klass'     => 'StandardError',
            'message'   => 'Hello Sinatra Error',
            'backtrace' => be_an(Array),
          },
          'tags' => [],
        )
      end
    end
  end

  pending 'when environment is development'
end
