# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'loga/version'

Gem::Specification.new do |spec|
  spec.name          = 'loga'
  spec.version       = Loga::VERSION
  spec.authors       = ['Funding Circle']
  spec.email         = ['engineering@fundingcircle.com']
  spec.summary       = 'Facilitate log aggregation via unified logging'
  spec.description   = 'Log aggregation through unified logging middleware, while respecting the original log format.'
  spec.license       = 'BSD-3-Clause'
  spec.homepage      = 'https://github.com/FundingCircle/loga'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin/) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)/)
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 2.3.8'
  spec.add_dependency 'rack'

  spec.add_development_dependency 'appraisal', '~> 2.0.2'
  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec',    '~> 3.0.0'
  spec.add_development_dependency 'rubocop',  '~> 0.40.0'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'guard',         '~> 2.13'
  spec.add_development_dependency 'guard-rubocop', '~> 1.2'
  spec.add_development_dependency 'guard-rspec',   '~> 4.7.3'
end
