# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

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

[2.1.0.pre.1]: https://github.com/FundingCircle/loga/compare/v2.0.0...v2.1.0.pre.1
[2.0.0]: https://github.com/FundingCircle/loga/compare/v2.0.0.pre.3...v2.0.0
[2.0.0.pre.3]: https://github.com/FundingCircle/loga/compare/v2.0.0.pre.2...v2.0.0.pre.3
[2.0.0.pre.2]: https://github.com/FundingCircle/loga/compare/v2.0.0.pre1...v2.0.0.pre.2
[2.0.0.pre1]: https://github.com/FundingCircle/loga/compare/v1.4.0...v2.0.0.pre1
[1.4.0]: https://github.com/FundingCircle/loga/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/FundingCircle/loga/compare/v1.2.1...v1.3.0
