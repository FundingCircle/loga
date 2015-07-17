# Loga [![Build Status](https://circleci.com/gh/FundingCircle/loga/tree/master.svg?style=shield&circle-token=9b81c3cf8468a8c3dc760f4c0398cf8914cb27d4)](https://circleci.com/gh/FundingCircle/loga/tree/master) [![Code Quality](https://codeclimate.com/repos/5563694f6956805723005d2f/badges/8eecb9144730614fb39e/gpa.svg)](https://codeclimate.com/repos/5563694f6956805723005d2f/feed) [![Test Coverage](https://codeclimate.com/repos/5563694f6956805723005d2f/badges/8eecb9144730614fb39e/coverage.svg)](https://codeclimate.com/repos/5563694f6956805723005d2f/coverage)

## Description

Loga defines a single log format, logger and middleware logger
to faciliate log aggregation.

It provides:
- Rack logger middleware to log HTTP requests
- Ruby logger

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

Loga.configure do |config|
  config.service_name    = 'marketplace'
  config.service_version = 'v1.0.0' or SHA
  config.device          = STDOUT or any instance of IO
end
```

Rails-less applications
```ruby
# config.ru
use Loga::Rack::Logger
```
NOTE: must have exception handler (e.g. action_dispatch.exception)

Rails applications
```ruby
# config/application.rb
config.middleware.insert_before Rails::Rack::Logger,
                                Loga::Rack::Logger
```

Custom events
```ruby
# Anywhere in your application
# Passing a String
Loga.logger.info('Hello World')
=> '{
  "@version":    "1.0",
  "host":        "example.com",
  "message":     "Hello World",
  "@timestamp":  "2015-12-15T03:30:05Z",
  "severity":    "INFO",
  "service":     {
    "name":      "hello_app",
    "version":   "abcdef"
  },
  "type":        "default"
}'

# Passing a Hash
Loga.logger.info(
  message:       'Hello World',  # REQUIRED
  type:          'cron',         # OPTIONAL
  timestamp:     Time,           # OPTIONAL
  event:         {               # OPTIONAL
    'color' =>   'red',
  },
  exception:     Exception,      # OPTIONAL
)
=> '{
  "@version":    "1.0",
  "host":        "example.com",
  "message":     "Hello World",
  "@timestamp":  "2015-12-15T03:30:05Z",
  "severity":    "INFO",
  "service":     {
    "name":      "hello_app",
    "version":   "abcdef"
  },
  "event":       {
    "color":     "red"
  },
  "type":        "cron"
}'
```

## Event types

Middleware augment payload with the `type` key to label events.

| event type        | description                       | middleware              |
|-------------------|-----------------------------------|-------------------------|
| request           | HTTP request and response         | Rack                    |
| default           | Event within the application      | Logger (not middleware) |

## Caveat

- Loga formats timestamps in seconds since UNIX epoch with 3 decimal places
  for milliseconds. Which is in accordance with GELF 1.1 specification.

## Contributing

1. Fork it ( https://github.com/FundingCircle/loga/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Credits

- [LogStashLogger](https://github.com/dwbutler/logstash-logger)
- [Rails](https://github.com/rails/rails)
- [RackLogstasher](https://github.com/alphagov/rack-logstasher)
