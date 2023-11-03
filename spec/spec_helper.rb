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
when /sidekiq(?<version>\d+)/
  sidekiq_version = $LAST_MATCH_INFO['version']
  case sidekiq_version
  when '51'
    rspec_pattern = [
      'spec/integration/sidekiq5_spec.rb',
      'spec/loga/sidekiq5/**/*_spec.rb',
      'spec/loga/sidekiq_spec.rb',
    ].join(',')
  when '60'
    rspec_pattern = [
      'spec/integration/sidekiq60_spec.rb',
      'spec/loga/sidekiq5/**/*_spec.rb',
      'spec/loga/sidekiq_spec.rb',
    ].join(',')
  when '61', '62', '63', '64'
    rspec_pattern = [
      'spec/integration/sidekiq61_spec.rb',
      'spec/loga/sidekiq6/**/*_spec.rb',
      'spec/loga/sidekiq_spec.rb',
    ].join(',')
  when '65'
    rspec_pattern = [
      'spec/integration/sidekiq65_spec.rb',
      'spec/loga/sidekiq6/**/*_spec.rb',
      'spec/loga/sidekiq_spec.rb',
    ].join(',')
  when '7', '70', '71'
    rspec_pattern = [
      'spec/integration/sidekiq7_spec.rb',
      'spec/loga/sidekiq7/**/*_spec.rb',
      'spec/loga/sidekiq_spec.rb',
    ].join(',')
  else
    raise "FIXME: Unknown sidekiq #{sidekiq_version} - update this file."
  end

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
