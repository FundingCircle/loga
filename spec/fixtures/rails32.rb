require 'action_controller/railtie'
require 'action_mailer/railtie'

Bundler.require(*Rails.groups(assets: %w[development test]))

STREAM = StringIO.new unless defined?(STREAM)

class Dummy < Rails::Application
  config.filter_parameters += [:password]
  config.secret_token = '32431967aed1c4357d311f27708a1837a938f07e0abfdefa6b8b398d7024c08c6b883ce9254cdd8573ce8e78f9dd192efff39395127811040fc695ab23677452'
  config.session_store :cookie_store, key: '_rails32_session'

  config.log_tags = [:uuid, 'TEST_TAG']
  config.loga = {
    device: STREAM,
    host: 'bird.example.com',
    service_name: 'hello_world_app',
    service_version: '1.0',
  }
  config.action_mailer.delivery_method = :test
  config.active_support.deprecation = :notify
end

class ApplicationController < ActionController::Base
  include Rails.application.routes.url_helpers
  protect_from_forgery

  def ok
    render text: 'Hello Rails'
  end

  def error
    nil.name
  end

  def show
    render json: params
  end

  def create
    render json: params
  end

  def new
    redirect_to :ok
  end

  def update
    @id = params[:id]
    render '/user'
  end
end

class FakeMailer < ActionMailer::Base
  default from: 'notifications@example.com'

  def self.send_email
    basic_mail.deliver
  end

  def basic_mail
    mail(
      to: 'user@example.com',
      subject: 'Welcome to My Awesome Site',
      body: 'Banana muffin',
      content_type: 'text/html',
    )
  end
end

Dummy.routes.append do
  get 'ok'        => 'application#ok'
  get 'error'     => 'application#error'
  get 'show'      => 'application#show'
  post 'users'    => 'application#create'
  get 'new'       => 'application#new'
  put 'users/:id' => 'application#update'
end

Dummy.initialize!
