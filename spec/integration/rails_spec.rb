require 'spec_helper'

describe 'Rack request logger with Rails', timecop: true do
  let(:json) do
    STREAM.rewind
    res = JSON.parse(STREAM.read)
    STREAM.close
    STREAM.reopen
    res
  end

  let(:app) { Rails.application }

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
        '_tags'               => ['471a34dc'],
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
        '_tags'               => ['471a34dc'],
      )
    end
  end
end
