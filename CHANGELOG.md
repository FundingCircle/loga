# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) 
and this project adheres to [Semantic Versioning](http://semver.org/).

## [1.4.0] - 2016-09-13
### Added
- Rails 5 support
- Silence ActionController::LogSubscriber

### Changed
- Update GELF payload to include `_request.controller` when available (Rails Controller/Action)

## [1.3.0] - 2016-09-07
### Changed
- Silence ActionDispatch::DebugExceptions' logger

[1.4.0]: https://github.com/FundingCircle/loga/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/FundingCircle/loga/compare/v1.2.1...v1.3.0
