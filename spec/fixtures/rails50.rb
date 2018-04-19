require 'action_controller/railtie'
require 'action_mailer/railtie'

Bundler.require(*Rails.groups)

STREAM = StringIO.new unless defined?(STREAM)

class Dummy < Rails::Application
  config.eager_load = true
  config.filter_parameters += [:password]
  config.secret_key_base = '2624599ca9ab3cf3823626240138a128118a87683bf03ab8f155844c33b3cd8cbbfa3ef5e29db6f5bd182f8bd4776209d9577cfb46ac51bfd232b00ab0136b24'
  config.session_store :cookie_store, key: '_rails50_session'

  config.log_tags = [:uuid, 'TEST_TAG']
  config.loga = {
    device: STREAM,
    host: 'bird.example.com',
    service_name: 'hello_world_app',
    service_version: '1.0',
  }
  config.action_mailer.delivery_method = :test
end

class ApplicationController < ActionController::Base
  include Rails.application.routes.url_helpers
  protect_from_forgery with: :null_session

  def ok
    render plain: 'Hello Rails'
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
    basic_mail.deliver_now
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
