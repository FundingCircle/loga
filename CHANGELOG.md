# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [2.6.0] - 2021-12-22
### Added
- Allow using the gem with rails 7
- Add a build for ruby 3.0

### Removed
- Remove build for ruby 2.3

## [2.5.4] - 2021-03-24
### Fixed
- Remove state from Rack middleware, to prevent race conditions where one request would overwrite the state of another

## [2.5.3] - 2020-10-27
### Fixed
- Support for sidekiq 6 - previous versions were causing sidekiq to crash with `Internal exception!`

## [2.5.2] - 2020-10-21
### Fixed
- Support for sidekiq 6

## [2.5.1] - 2020-01-02
### Fixed
- Fixed a long standing bug that would mask exceptions raised by the host application when serving requests. The original exception would be replaced with a `TypeError` one due to a HTTP status code not being available within `Loga::Rack::Logger`.

## [2.5.0] - 2019-11-12
### Added
- Add support for rails 6

## [2.4.0] - 2019-09-03
### Fixed
- `duration` in the `sidekiq` integration is now calculated correctly
### Added
- Add build for ruby 2.6
### Removed
- Remove build for ruby 2.2

## [2.3.1] - 2019-05-14
### Added
New configuration option `hide_pii` which defaults to `true` to hide email addresses in logs that get generate when an email is sent through action_mailer

## [2.3.0] - 2018-06-29
### Added
Support for Sidekiq `~> 5.0`.

## [2.2.0] - 2018-05-10
### Added
Subscribe to `ActionMailer` events
  - deliver
  - process
  - receive

## [2.1.2] - 2016-12-08
### Fixed
- `Loga::Rack::Logger` looks into `env['rack.exception']` for exceptions

## [2.1.1] - 2016-12-02
### Fixed
- Encoding error when converting uploaded file to JSON
[rails/rails#25250](https://github.com/rails/rails/issues/25250)

## [2.1.0] - 2016-11-17
## [2.1.0.pre.1]
### Changed
- Replace `ActiveSupport::Logger::SimpleFormatter` with `Loga::Formatters::SimpleFormatter`
when using simple format. The formatter adds level, timestamp, pid and tags prepended to the message

## [2.0.0] - 2016-10-27
## [2.0.0.pre.3]
## [2.0.0.pre.2]
## [2.0.0.pre1]
### Added
- Human readable formatter `SimpleFormatter`
- `LOGA_FORMAT` environment variable to switch between (gelf|simple) formatters
- Added `format` and `filter_exceptions` configuration options

### Changed
#### Configuration interface
- Configure via Hash instead of Block
- String only `service_version` configuration option

#### Rails
- Use Loga everywhere with environment based configuration
- Added `ActiveRecord::RecordNotFound` to default `filter_exceptions`
- Removed `enabled` and `silence_rails_rack_logger` configure options
- Enforce Rails configuration options over Loga where possible

#### Sinatra
- Removed logger and tags parameters in `Loga::Rack::Logger`

### Fixed
- Uninitialized `Loga.logger` in Rails

## [1.4.0] - 2016-09-13
### Added
- Rails 5 support
- Silence ActionController::LogSubscriber

### Changed
- Update GELF payload to include `_request.controller` when available (Rails Controller/Action)

## [1.3.0] - 2016-09-07
### Changed
- Silence ActionDispatch::DebugExceptions' logger

[2.1.2]: https://github.com/FundingCircle/loga/compare/v2.1.1...v2.1.2
[2.1.1]: https://github.com/FundingCircle/loga/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/FundingCircle/loga/compare/v2.0.0...v2.1.0
[2.1.0.pre.1]: https://github.com/FundingCircle/loga/compare/v2.0.0...v2.1.0.pre.1
[2.0.0]: https://github.com/FundingCircle/loga/compare/v1.4.0...v2.0.0
[2.0.0.pre.3]: https://github.com/FundingCircle/loga/compare/v2.0.0.pre.2...v2.0.0.pre.3
[2.0.0.pre.2]: https://github.com/FundingCircle/loga/compare/v2.0.0.pre1...v2.0.0.pre.2
[2.0.0.pre1]: https://github.com/FundingCircle/loga/compare/v1.4.0...v2.0.0.pre1
[1.4.0]: https://github.com/FundingCircle/loga/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/FundingCircle/loga/compare/v1.2.1...v1.3.0
