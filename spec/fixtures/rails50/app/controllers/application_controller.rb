class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

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
