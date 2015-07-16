class ApplicationController < ActionController::Base
  protect_from_forgery

  def ok
    render text: 'Hello Rails'
  end

  def error
    fail StandardError, 'Hello Rails Error'
  end
end
