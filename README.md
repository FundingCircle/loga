# Loga

[![Gem Version](https://badge.fury.io/rb/loga.svg)](https://badge.fury.io/rb/loga)
[![Build Status](https://circleci.com/gh/FundingCircle/loga/tree/master.svg?style=shield&circle-token=9b81c3cf8468a8c3dc760f4c0398cf8914cb27d4)](https://circleci.com/gh/FundingCircle/loga/tree/master)
[![Code Quality](https://codeclimate.com/repos/5563694f6956805723005d2f/badges/8eecb9144730614fb39e/gpa.svg)](https://codeclimate.com/repos/5563694f6956805723005d2f/feed)
[![Test Coverage](https://codeclimate.com/repos/5563694f6956805723005d2f/badges/8eecb9144730614fb39e/coverage.svg)](https://codeclimate.com/repos/5563694f6956805723005d2f/coverage)

## Description

Loga provides consistent logging across frameworks and environments.

Includes:
- One logger for all environments
- Human readable logs for development
- Structured logs for production ([GELF](http://docs.graylog.org/en/2.1/pages/gelf.html))
- One Rack logger for all Rack based applications

## TOC

- [Installation](#installation)
  - [Rails](#rails)
    - [Reduced logs](#reduced-logs)
    - [Request log tags](#request-log-tags)
  - [Sinatra](#sinatra)
- [Output example](#output-example)
   - [GELF Format](#gelf-format)
   - [Simple Format](#simple-format)
- [Road map](#road-map)
- [Contributing](#contributing)
  - [Running tests](#running-tests)
- [Credits](#credits)
- [License](#license)

## Installation

Add this line to your application's Gemfile:

```
gem 'loga', git: 'git@github.com:FundingCircle/loga.git'
```

### Rails

Let Loga know what your application name is and Loga will do the rest.

```ruby
# config/application.rb
class MyApp::Application < Rails::Application
  config.loga = { service_name: 'MyApp' }
end
```

Loga hooks into the Rails logger initialization process and defines its own logger for all environments.

The logger configuration is adjusted based on the environment:

|        | Production | Test         | Development | Others |
|--------|------------|--------------|-------------|--------|
| Output | STDOUT     | log/test.log | STDOUT      | STDOUT |
| Format | gelf       | simple       | simple      | simple |

You can customize the configuration to your liking:

```ruby
# config/application.rb
class MyApp::Application < Rails::Application
  config.loga = {
    device:       File.open("log/application.log", 'a'),
    format:       :gelf,
    service_name: 'MyApp',
  }
end
```

Loga leverages existing Rails configuration options:

- `config.filter_parameters`
- `config.log_level`
- `config.log_tags`

Use these options to customize Loga instead of the Loga options hash.

Inside your application use `Rails.logger` instead of `Loga.logger`, even though
they are equivalent, to prevent lock-in.

#### Reduced logs

When the format set to `gelf` requests logs are reduced to a single log entry, which
could include an exception.

This is made possible by silencing these loggers:

- `Rack::Request::Logger`
- `ActionDispatch::DebugExceptions`
- `ActionController::LogSubscriber`
- `ActionView::LogSubscriber`

#### Request log tags

To provide consistency between Rails and other Rack frameworks, tags (e.i `config.log_tags`)
are computed with a [Loga::Rack::Request](lib/loga/rack/request.rb) as
opposed to a `ActionDispatch::Request`.

### Sinatra

With Sinatra Loga needs to be configured manually:

```ruby
require 'loga'

Loga.configure(
  filter_parameters: [:password],
  format: :gelf,
  service_name: 'my_app',
  tags: [:uuid],
)

use Loga::Rack::RequestId
use Loga::Rack::Logger

use MyApp
run Sinatra::Application
```

You can now use `Loga.logger` or assign it to your existing logger.
The above configuration also inserts two middleware:

- `Loga::Rack::RequestId` makes the request id available to the request logger
- `Loga::Rack::Logger` logs requests

You can easily switch between formats by using the `LOGA_FORMAT`
environment variable. The `format` key in the options takes precedence over the
environment variable therefore it must be removed.

```
LOGA_FORMAT=simple rackup
```

## Output Example

### GELF Format

Rails request logger: (includes controller/action name):

`curl localhost:3000/ok -X GET -H "X-Request-Id: 12345"`

```json
{
   "_request.status":     200,
   "_request.method":     "GET",
   "_request.path":       "/ok",
   "_request.params":     {},
   "_request.request_id": "12345",
   "_request.request_ip": "127.0.0.1",
   "_request.user_agent": null,
   "_request.controller": "ApplicationController#ok",
   "_request.duration":   0,
   "_type":               "request",
   "_service.name":       "my_app",
   "_service.version":    "1.0",
   "_tags":               "12345",
   "short_message":       "GET /ok 200 in 0ms",
   "timestamp":           1450150205.123,
   "host":                "example.com",
   "level":               6,
   "version":             "1.1"
}
```

Sinatra request output is identical to Rails but without the `_request.controller` key.

Logger output:

```ruby
Rails.logger.info('I love Loga')
# or
Loga.logger.info('I love Loga')
```

```json
{
  "_service.name":     "my_app",
  "_service.version":  "v1.0.0",
  "_tags":             "12345",
  "host":              "example.com",
  "level":             6,
  "short_message":     "I love Loga",
  "timestamp":         1450150205.123,
  "version":           "1.1"
}
```

### Simple Format

Request logger:

`curl localhost:3000/ok -X GET -H "X-Request-Id: 12345"`

Rails

```
I, [2016-11-15T16:05:03.614081+00:00 #1][12345] Started GET "/ok" for ::1 at 2016-11-15 16:05:03 +0000
I, [2016-11-15T16:05:03.620176+00:00 #1][12345] Processing by ApplicationController#ok as HTML
I, [2016-11-15T16:05:03.624807+00:00 #1][12345]   Rendering text template
I, [2016-11-15T16:05:03.624952+00:00 #1][12345]   Rendered text template (0.0ms)
I, [2016-11-15T16:05:03.625137+00:00 #1][12345] Completed 200 OK in 5ms (Views: 4.7ms)
```

Sinatra

```
I, [2016-11-15T16:10:08.645521+00:00 #1][12345] GET /ok 200 in 0ms type=request data={:request=>{"status"=>200, "method"=>"GET", "path"=>"/ok", "params"=>{}, "request_id"=>"12345", "request_ip"=>"127.0.0.1", "user_agent"=>nil, "duration"=>0}}
```

Logger output:

```ruby
Loga.logger.info('I love Loga')
```

```
I, [2015-12-15T09:30:05.123000+06:00 #999] I love Loga
```

## Road map

Consult the [milestones](https://github.com/FundingCircle/loga/milestones).

## Contributing

Loga is in active development, feedback and contributions are welcomed.

### Running tests

This project uses [`appraisal`](https://github.com/thoughtbot/appraisal/tree/v2.0.2)
to run tests against different versions of dependencies (e.g. Rails, Sinatra).

Install Loga dependencies with `bundle install` and then appraisals
with `bundle exec appraisal install`.

Run all tests with `bundle exec appraisal rspec`.

You can run tests for one appraisal with `bundle exec appraisal appraisal-name rspec`.
Refer to the [Appraisals](Appraisals) file for a complete lists of appraisals.

Prefix test command with RACK\_ENV to switch between environments for Rack based tests
`RACK_ENV=production bundle exec appraisal rspec`.

Experiment Guard support introduced to ease running tests locally `bundle exec guard`.

[CI](https://circleci.com/gh/FundingCircle/loga) results are the source of truth.

## Credits

- [Lograge](https://github.com/roidrage/lograge)
- [LogStashLogger](https://github.com/dwbutler/logstash-logger)
- [Rails](https://github.com/rails/rails)
- [RackLogstasher](https://github.com/alphagov/rack-logstasher)

## License

Copyright (c) 2015 Funding Circle. All rights reserved.

Distributed under the BSD 3-Clause License.
