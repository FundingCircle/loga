RSpec.shared_examples 'request logger' do
  describe 'get request' do
    it 'logs the request' do
      get '/ok',
          { username: 'yoshi' },
          'HTTP_USER_AGENT' => 'Chrome', 'HTTP_X_REQUEST_ID' => '471a34dc'

      expect(last_log_entry).to include(
        'version'             => '1.1',
        'host'                => 'bird.example.com',
        'short_message'       => 'GET /ok?username=yoshi 200 in 0ms',
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
        '_tags'               => '471a34dc TEST_TAG',
      )
    end
  end

  describe 'post request' do
    let(:json_response) { JSON.parse(last_response.body) }

    it 'logs the request' do
      post '/users?username=yoshi',
           { email: 'hello@world.com' },
           'HTTP_USER_AGENT' => 'Chrome', 'HTTP_X_REQUEST_ID' => '471a34dc'

      expect(last_log_entry).to include(
        'version'             => '1.1',
        'host'                => 'bird.example.com',
        'short_message'       => 'POST /users?username=yoshi 200 in 0ms',
        'timestamp'           => 1_450_150_205.123,
        'level'               => 6,
        '_type'               => 'request',
        '_service.name'       => 'hello_world_app',
        '_service.version'    => '1.0',
        '_request.method'     => 'POST',
        '_request.path'       => '/users',
        '_request.params'     => { 'username' => 'yoshi', 'email' => 'hello@world.com' },
        '_request.request_ip' => '127.0.0.1',
        '_request.user_agent' => 'Chrome',
        '_request.status'     => 200,
        '_request.request_id' => '471a34dc',
        '_request.duration'   => 0,
        '_tags'               => '471a34dc TEST_TAG',
      )
    end

    it 'preseves request parameters' do
      post '/users?username=yoshi', email: 'hello@world.com'
      expect(json_response)
        .to include('email' => 'hello@world.com', 'username' => 'yoshi')
    end
  end

  describe 'request with redirect' do
    it 'specifies the original path' do
      get '/new', {}, 'HTTP_USER_AGENT' => 'Chrome', 'HTTP_X_REQUEST_ID' => '471a34dc'

      expect(last_log_entry).to include(
        'version'             => '1.1',
        'host'                => 'bird.example.com',
        'short_message'       => 'GET /new 302 in 0ms',
        'timestamp'           => 1_450_150_205.123,
        'level'               => 6,
        '_type'               => 'request',
        '_service.name'       => 'hello_world_app',
        '_service.version'    => '1.0',
        '_request.method'     => 'GET',
        '_request.path'       => '/new',
        '_request.params'     => {},
        '_request.request_ip' => '127.0.0.1',
        '_request.user_agent' => 'Chrome',
        '_request.status'     => 302,
        '_request.request_id' => '471a34dc',
        '_request.duration'   => 0,
        '_tags'               => '471a34dc TEST_TAG',
      )
    end
  end

  context 'when the request raises an exception' do
    it 'logs the request with the exception' do
      get '/error',
          { username: 'yoshi' },
          'HTTP_USER_AGENT' => 'Chrome', 'HTTP_X_REQUEST_ID' => '471a34dc'

      expect(last_log_entry).to include(
        'version'              => '1.1',
        'host'                 => 'bird.example.com',
        'short_message'        => 'GET /error?username=yoshi 500 in 0ms',
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
        '_exception.klass'     => 'NoMethodError',
        '_exception.message'   => "undefined method `name' for nil:NilClass",
        '_exception.message'   => start_with("undefined method `name' for nil:NilClass"),
        '_exception.backtrace' => be_a(String),
        '_tags'                => '471a34dc TEST_TAG',
      )
    end
  end

  describe 'when request causes 404' do
    it 'does not log the framework exception' do
      get '/not_found', {}, 'HTTP_X_REQUEST_ID' => '471a34dc'

      expect(last_log_entry).to include(
        'version'              => '1.1',
        'host'                 => 'bird.example.com',
        'short_message'        => 'GET /not_found 404 in 0ms',
        'timestamp'            => 1_450_150_205.123,
        'level'                => 6,
        '_type'                => 'request',
        '_service.name'        => 'hello_world_app',
        '_service.version'     => '1.0',
        '_request.method'      => 'GET',
        '_request.path'        => '/not_found',
        '_request.params'      => {},
        '_request.request_ip'  => '127.0.0.1',
        '_request.user_agent'  => nil,
        '_request.status'      => 404,
        '_request.request_id'  => '471a34dc',
        '_request.duration'    => 0,
        '_tags'               => '471a34dc TEST_TAG',
      )
    end
  end

  describe 'when the request includes a filtered parameter' do
    before { get '/ok', params }

    context 'when params is shallow' do
      let(:params) { { password: 'password123' } }

      it 'filters the parameter from the params hash' do
        expect(last_log_entry).to include(
          '_request.params' => { 'password' => '[FILTERED]' },
        )
      end

      it 'filters the parameter from the message' do
        expect(last_log_entry).to include(
          'short_message' => 'GET /ok?password=[FILTERED] 200 in 0ms',
        )
      end
    end

    context 'when params is nested' do
      let(:params) { { users: [password: 'password123'] } }

      it 'filters the parameter from the params hash' do
        expect(last_log_entry).to include(
          '_request.params' => { 'users' => ['password' => '[FILTERED]'] },
        )
      end

      it 'filters the parameter from the message' do
        expect(last_log_entry).to include(
          'short_message' => 'GET /ok?users[][password]=[FILTERED] 200 in 0ms',
        )
      end
    end
  end

  describe 'when the request uploads a binary file' do
    it 'logs the request' do
      post '/users?username=yoshi',
           bob_file: Rack::Test::UploadedFile.new('spec/fixtures/random_bin')

      expect(last_log_entry).to include(
        'short_message'       => 'POST /users?username=yoshi 200 in 0ms',
        'level'               => 6,
        '_request.params'     => {
          'username' => 'yoshi',
          'bob_file' => include(
            'filename' => 'random_bin',
            'name' => 'bob_file',
          ),
        },
      )
    end
  end
end
