require 'byebug'
require 'pry'
require 'support/gethostname_shared'
require 'support/helpers'
require 'support/request_spec'
require 'support/timecop_shared'
require 'rack/test'
require 'simplecov'

SimpleCov.start do
  command_name "ruby-#{RUBY_VERSION}-#{File.basename(ENV['BUNDLE_GEMFILE'], '.gemfile')}"

  # Exclude specs from showing up in the code coverage report.
  add_filter 'spec/'
end

case ENV['BUNDLE_GEMFILE']
when /rails/
  rspec_pattern = 'integration/rails/**/*_spec.rb'
  /(?<appraisal>rails\d{2})\.gemfile/ =~ ENV['BUNDLE_GEMFILE']
  require 'rails'
  require 'action_mailer'
  require File.expand_path("../fixtures/#{appraisal}.rb",  __FILE__)
when /sinatra/
  rspec_pattern = 'integration/sinatra_spec.rb'
  require 'json'
  require 'sinatra'
  require 'loga'
when /unit/
  rspec_pattern = 'unit/**/*_spec.rb'
  require 'loga'
when /sidekiq/
  sidekiq_specs = [
    'integration/sidekiq_spec.rb',
    'spec/loga/sidekiq/**/*_spec.rb',
    'spec/loga/sidekiq_spec.rb',
  ]

  rspec_pattern = sidekiq_specs.join(',')

  require 'sidekiq'
  require 'sidekiq/cli'
  require 'loga'
else
  raise 'BUNDLE_GEMFILE is unknown. Ensure the appraisal is present in Appraisals'
end

RSpec.configure do |config|
  config.include Helpers
  config.include Rack::Test::Methods

  config.pattern = rspec_pattern

  config.mock_with :rspec do |mocks|
    mocks.allow_message_expectations_on_nil = false
    mocks.transfer_nested_constants = true
    mocks.verify_doubled_constant_names = true
  end
end
