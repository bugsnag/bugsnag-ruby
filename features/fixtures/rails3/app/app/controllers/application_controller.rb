class ApplicationController < ActionController::Base
  protect_from_forgery

  def index
    render json: {}
  end

  def unhandled
    generate_unhandled_error
  end
end
