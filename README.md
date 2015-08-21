# Loga [![Build Status](https://circleci.com/gh/FundingCircle/loga/tree/master.svg?style=shield&circle-token=9b81c3cf8468a8c3dc760f4c0398cf8914cb27d4)](https://circleci.com/gh/FundingCircle/loga/tree/master) [![Code Quality](https://codeclimate.com/repos/5563694f6956805723005d2f/badges/8eecb9144730614fb39e/gpa.svg)](https://codeclimate.com/repos/5563694f6956805723005d2f/feed) [![Test Coverage](https://codeclimate.com/repos/5563694f6956805723005d2f/badges/8eecb9144730614fb39e/coverage.svg)](https://codeclimate.com/repos/5563694f6956805723005d2f/coverage)

## Description

Loga defines a single log format, logger and middleware logger
to faciliate log aggregation.

It provides:
- Rack logger middleware to log HTTP requests
- Ruby logger

## Installation

Add this line to your application's Gemfile:

    gem 'loga', git: 'git@github.com:FundingCircle/loga.git'

And then execute:

    $ bundle

## Usage

Loga integrates well with Rails and Sinatra frameworks. It also works in projects
using plain Ruby.

### Rails applications

In Rails applications initialization and middleware insertion is catered by
the Railtie.

```ruby
# config/environments/production.rb
...
config.loga.configure do |loga|
  # See configuration section
end
...
```

### Ruby and Sinatra/Rack applications

In Ruby applications Loga must be required and configured.

```ruby
# .../initializers/loga.rb
require 'loga'

Loga.configure do |loga|
  # See configuration section
end
Loga.initialize!
```
Log requests in Rack applications with Loga middleware.

`RequestId` and `Logger` must be inserted early in the middleware chain.

```ruby
# config.ru
use Loga::Rack::RequestId
use Loga::Rack::Logger, Loga.logger

user Marketplace
run Sinatra::Application
```

### Configuration

| Option          | Type          | Default | Description                                                                                        |
|-----------------|---------------|---------|----------------------------------------------------------------------------------------------------|
| host            | String        | nil     | Service hostname. When nil the hostname is computed with `Socket.gethostname`                      |
| service_version | String/Symbol | :git    | Service version is embedded in every message. When Symbol the version is computed with a strategy. |
| service_name    | String        | nil     | Service name is embedded in every message                                                          |
| device          | IO            | nil     | The device the logger writes to                                                                    |
| sync            | Boolean       | true    | Sync IO                                                                                            |
| level           | Symbol        | :info   | The level to logger logs at                                                                        |
| enabled         | Boolean       | true    | Enable/Disable Loga in Rails                                                                       |

## Sample output

```ruby
# Anywhere in your application
Loga.logger.info('Hello World')
```
```json
//GELF Output
{
  "version":           "1.1",
  "host":              "example.com",
  "short_message":     "Hello World",
  "timestamp":         1450150205.123,
  "level":             6,
  "_service.name":     "marketplace",
  "_service.version":  "v1.0.0",
  "_tags":             []
}
```

## Event types

Middleware augment payload with the `type` key to label events.

| event type        | description                       | middleware              |
|-------------------|-----------------------------------|-------------------------|
| request           | HTTP request and response         | Rack                    |

## Caveat

- Loga formats timestamps in seconds since UNIX epoch with 3 decimal places
  for milliseconds. Which is in accordance with GELF 1.1 specification.


## Road Map

Consult the [milestones](https://github.com/FundingCircle/loga/milestones).

## Contributing

### Overview

1. Fork it ( https://github.com/FundingCircle/loga/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

### Running tests

This project uses [`appraisal`](https://github.com/thoughtbot/appraisal/tree/v2.0.2) to run tests against different versions of dependencies (e.g. Rails, Sinatra).

Once you have run bundle, you can install the test dependencies with `bundle exec appraisal install`.

Run all tests with `bundle exec appraisal rspec`.

You can run tests for one appraisal with `bundle exec appraisal appraisal-name rspec`.

With Rack applications prepend RACK\_ENV to switch between environments `RACK_ENV=production bundle exec appraisal rspec`

Refer to the [Appraisals](https://github.com/FundingCircle/loga/blob/master/Appraisals) file for a complete lists of appraisals.

## Credits

- [LogStashLogger](https://github.com/dwbutler/logstash-logger)
- [Rails](https://github.com/rails/rails)
- [RackLogstasher](https://github.com/alphagov/rack-logstasher)
