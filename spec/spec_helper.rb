require 'pry'
require 'support/gethostname_shared'
require 'support/helpers'
require 'support/request_spec'
require 'support/timecop_shared'
require 'rack/test'
require 'simplecov'

SimpleCov.start

case ENV['BUNDLE_GEMFILE']
when /rails/
  rspec_pattern = 'integration/rails/**/*_spec.rb'
  /(?<appraisal>rails\d{2})\.gemfile/ =~ ENV['BUNDLE_GEMFILE']
  require 'rails'
  require File.expand_path("../fixtures/#{appraisal}.rb",  __FILE__)
when /sinatra/
  rspec_pattern = 'integration/sinatra_spec.rb'
  require 'json'
  require 'sinatra'
  require 'loga'
when /unit/
  rspec_pattern = 'unit/**/*_spec.rb'
  require 'loga'
else
  raise 'BUNDLE_GEMFILE is unknown. Ensure the appraisal is present in Appraisals'
end

RSpec.configure do |config|
  config.include Helpers
  config.include Rack::Test::Methods

  config.pattern = rspec_pattern
end
