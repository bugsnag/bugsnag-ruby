class UnhandledController < ActionController::Base
  protect_from_forgery

  def index
    render json: {}
  end

  def error
    generate_unhandled_error
  end
end
