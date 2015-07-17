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
  spec.description   = 'Log all the things through middleware and respecting the same format'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin/) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)/)
  spec.require_paths = ['lib']

  spec.add_dependency 'rack'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec',    '~> 3.0.0'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'rubocop',  '~> 0.30.0'
  spec.add_development_dependency 'sinatra',  '~> 1.4.0'
  spec.add_development_dependency 'rails',    '~> 4.1.0'
end
