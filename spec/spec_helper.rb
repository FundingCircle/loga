# Set timezone to UTC
ENV['TZ'] = 'UTC'

require 'loga'
require 'pry'
require 'rack/test'
require 'rubocop'
require 'support/helpers'
require 'support/loga_initialize_shared'
require 'support/timecop_shared.rb'

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include Helpers

  config.before do
    allow(Socket).to receive(:gethostname).and_return(hostname_anchor)
  end
end
