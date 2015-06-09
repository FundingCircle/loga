# Set timezone to UTC
ENV['TZ'] = 'UTC'

require 'loga'
require 'rack/test'
require 'pry'
require 'support/helpers'

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include Helpers

  config.before do
    allow(Socket).to receive(:gethostname).and_return(hostname_anchor)
  end
end
