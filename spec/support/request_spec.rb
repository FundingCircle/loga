shared_examples 'request logger' do
  context 'get request' do
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

  context 'post request' do
    let(:json_response) { JSON.parse(last_response.body) }

    it 'logs the request' do
      post '/users?username=yoshi',
           { email: 'hello@world.com' },
           'HTTP_USER_AGENT' => 'Chrome', 'HTTP_X_REQUEST_ID' => '471a34dc'

      expect(json).to match(
        'version'             => '1.1',
        'host'                => 'bird.example.com',
        'short_message'       => 'POST /users?username=yoshi',
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
        '_tags'               => ['471a34dc'],
      )
    end

    it 'preseves request parameters' do
      post '/users?username=yoshi', email: 'hello@world.com'
      expect(json_response).to include('email' => 'hello@world.com', 'username' => 'yoshi')
    end
  end

  context 'request with redirect' do
    it 'specifies the original path' do
      get '/new', {}, 'HTTP_USER_AGENT' => 'Chrome', 'HTTP_X_REQUEST_ID' => '471a34dc'

      expect(json).to match(
        'version'             => '1.1',
        'host'                => 'bird.example.com',
        'short_message'       => 'GET /new',
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
        '_exception.klass'     => 'NoMethodError',
        '_exception.message'   => "undefined method `name' for nil:NilClass",
        '_exception.backtrace' => be_a(String),
        '_tags'               => ['471a34dc'],
      )
    end
  end

  describe 'when request causes 404' do
    pending 'does not log the framework execption'
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
