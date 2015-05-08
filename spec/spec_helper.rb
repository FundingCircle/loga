require 'service_logger'
require 'rack/test'
require 'pry'
require 'support/helpers'

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include Helpers
end
