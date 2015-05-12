# ServiceLogger

## Description
ServiceLogger defines a single log format, logger and middleware logger
to faciliate log aggregation.

It provides provides:
- Rack logger middleware
- Sidekiq logger middleware to log jobs
- Ruby logger
- GELF log formatter
- GELF log device

## Road Map

- [ ] CI setup with ruby 1.9 and 2.0
- [ ] Setting to limit backtrace size
- [ ] Setting to filter out sensitive request parameters
- [ ] Support standard Ruby logger message input
- [ ] Hutch logging integration (Producer and Consumer)
- [ ] ActionMailer integration (New event_types)
- [ ] GELF additional fields naming retrospective
- [ ] Hooks to augment data being logged

## Installation

Add this line to your application's Gemfile:

    gem 'service_logger'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install service_logger

## Usage

Configuration
```ruby
# config/initializers/service_logger.rb
target = ServiceLogger::GELFUPDLogDevice.new(host: '192.168.99.100')

ServiceLogger.configure do |config|
  config.service_name   = 'marketplace'
  config.service_verion = 'v1.0.0' or SHA
  config.log_target     = target
end
```

Rails-less applications
```ruby
# config.ru
use ServiceLogger::Rack::Logger
```

Rails applications
```ruby
# config/application.rb
config.middleware.insert_after Rack::MethodOverride,
                               ServiceLogger::Rack::Logger
```

Sidekiq
```ruby
# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.insert_before Sidekiq::Middleware::Server::RetryJobs,
                        ServiceLogger::Sidekiq::ServerLogger
  end
  config.client_middleware do |chain|
    chain.add ServiceLogger::Sidekiq::ClientLogger
  end
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add ServiceLogger::Sidekiq::ClientLogger
  end
end
```

Custom events
```ruby
# Anywhere in your application
ServiceLogger.logger.info(short_message: 'Some message')
```

## Event types
Middleware augment the GELF payload with the `_event_type` key to label events.

| event type        | description                       | middleware              |
|-------------------|-----------------------------------|-------------------------|
| http_request      | HTTP request and response         | Rack                    |
| job_enqueued      | Sidekiq client enqueues a job     | SidekiqClient           |
| job_consumed      | Sidekiq worker consumes a job     | SidekiqServer           |
| message_published | Publisher publishes a RMQ message | TODO                    |
| message_consumed  | Consumer consumes a RMQ message   | TODO                    |
| custom            | Event within the application      | Logger (not middleware) |

## Sample GELF

:warning: Coming up

## Contributing

1. Fork it ( https://github.com/[my-github-username]/service_logger/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Credits
- [Sidekiq](https://github.com/mperham/sidekiq)
- [Rails](https://github.com/rails/rails)
- [RackLogstasher](https://github.com/alphagov/rack-logstasher)
- [gelf-rb](https://github.com/Graylog2/gelf-rb)
