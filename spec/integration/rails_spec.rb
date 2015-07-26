require 'spec_helper'

describe 'Integration with Rails', timecop: true do
  let(:app) { Rails.application }

  describe 'request logger' do
    let(:json_entries) do
      [].tap do |entries|
        STREAM.tap do |s|
          s.rewind
          s.read.split("\n").each do |line|
            entries << JSON.parse(line)
          end
          s.close
          s.reopen
        end
      end
    end

    let(:json) { json_entries.last }

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

    describe 'when the request includes a filtered parameter' do
      before { get '/ok', password: 'password123' }

      it 'filters the parameter from the params hash' do
        expect(json).to include(
          '_request.params' => { 'password' => '[FILTERED]' },
        )
      end

      it 'filters the parameter from the message' do
        expect(json).to include(
          'short_message' => 'GET /ok?password=[FILTERED]',
        )
      end
    end
  end

  describe 'Railtie' do
    let(:middlewares) { app.middleware.middlewares }

    it 'inserts Loga::Rack::Logger middleware after Rails::Rack::Logger' do
      expect(middlewares.index(Loga::Rack::Logger))
        .to eq(middlewares.index(Rails::Rack::Logger) + 1)
    end
  end
end
