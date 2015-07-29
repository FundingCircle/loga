class ApplicationController < ActionController::Base
  protect_from_forgery

  def ok
    render text: 'Hello Rails'
  end

  def error
    nil.name
  end
end
