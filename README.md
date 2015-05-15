# Loga

## Description

Loga defines a single log format, logger and middleware logger
to faciliate log aggregation.

It provides provides:
- Rack logger middleware
- Sidekiq logger middleware to log jobs
- Ruby logger
- GELF log formatter
- GELF log device

## Road Map to v1.0.0

Follow the [milestone](https://github.com/FundingCircle/loga/milestones/The%20road%20to%20v1.0.0)

## Installation

Add this line to your application's Gemfile:

    gem 'loga'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install loga

## Usage

Configuration
```ruby
# config/initializers/loga.rb
target = Loga::GELFUPDLogDevice.new(host: '192.168.99.100')

Loga.configure do |config|
  config.service_name    = 'marketplace'
  config.service_version = 'v1.0.0' or SHA
  config.device          = target
end
```

Rails-less applications
```ruby
# config.ru
use Loga::Rack::Logger
```

Rails applications
```ruby
# config/application.rb
config.middleware.insert_after Rack::MethodOverride,
                               Loga::Rack::Logger
```

Sidekiq
```ruby
# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.insert_before Sidekiq::Middleware::Server::RetryJobs,
                        Loga::Sidekiq::ServerLogger
  end
  config.client_middleware do |chain|
    chain.add Loga::Sidekiq::ClientLogger
  end
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add Loga::Sidekiq::ClientLogger
  end
end
```

Custom events
```ruby
# Anywhere in your application
# Passing a String
Loga.logger.info('Hello World')
=> '{
  "version":           "1.1",
  "host":              "example.com",
  "short_message":     "Hello World",
  "timestamp":         "1450171805.123",
  "level":             "6",
  "_service.name":     "hello_app",
  "_service.version":  "abcdef",
  "_event":            "unknown"
}'

# Passing a Hash
Loga.logger.info(
  short_message: 'Hello World',               # REQUIRED
  full_message:  'Hello World and the Moon',  # OPTIONAL
  type:          'new_user',                  # OPTIONAL
  timestamp:     Time,                        # OPTIONAL
  data:          {                            # OPTIONAL
    'color' => 'red',
    'user'  => {
      'name' => 'Bob',
    },
  },
  exception:     Exception,                   # OPTIONAL
)
=> '{
  "version":           "1.1",
  "host":              "example.com",
  "short_message":     "GET /hello_world",
  "timestamp":         "1450171805.123",
  "level":             "6",
  "_service.name":     "hello_app",
  "_service.version":  "abcdef",
  "_event":            "unknown",
  "_color":            "red",
  "_user.name":        "Bob"
}'
```

## Event types

Middleware augment the GELF payload with the `_event` key to label events.

| event type        | description                       | middleware              |
|-------------------|-----------------------------------|-------------------------|
| http_request      | HTTP request and response         | Rack                    |
| job_enqueued      | Sidekiq client enqueues a job     | SidekiqClient           |
| job_consumed      | Sidekiq worker consumes a job     | SidekiqServer           |
| message_published | Publisher publishes a RMQ message | TODO                    |
| message_consumed  | Consumer consumes a RMQ message   | TODO                    |
| unknown           | Event within the application      | Logger (not middleware) |

## Sample GELF

:warning: Coming up

## Development with GrayLog

Install GrayLog with docker.

Requirements:
 - `docker-machine`
 - `docker-compose`

```yml
# docker-compose.yml
graylog:
  image: graylog2/allinone
  ports:
    - "9000:9000"
    - "12201:12201"
    - "12201:12201/udp"
  volumes:
    # Paths with Boot2docker
    - /mnt/sda1/graylog/data:/var/opt/graylog/data
    - /mnt/sda1/graylog/logs:/var/log/graylog
```

0. Start the cluster with `docker-compose up`
0. Browse to `your.docker.machine.ip:9000` and login with the `admin`
   user/password.
0. Navigate to `System` -> `Inputs` where you can `Launch new input`
   GELF UDP with default options.
0. Send all the things

## Contributing

1. Fork it ( https://github.com/FundingCircle/loga/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Credits

- [Sidekiq](https://github.com/mperham/sidekiq)
- [Rails](https://github.com/rails/rails)
- [RackLogstasher](https://github.com/alphagov/rack-logstasher)
- [gelf-rb](https://github.com/Graylog2/gelf-rb)
