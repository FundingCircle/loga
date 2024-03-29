
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
end
