require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

STREAM = StringIO.new unless defined?(STREAM)

module Rails50
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.log_tags = [ :request_id, 'TEST_TAG' ]
    config.loga.configure do |loga|
      loga.service_name = 'hello_world_app'
      loga.service_version = '1.0'
      loga.host = 'bird.example.com'
      loga.device = STREAM
    end
  end
end