class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def index
    render json: {}
  end

  def unhandled
    generate_unhandled_error
  end

  def handled
    Bugsnag.notify(RuntimeError.new("handled error"))
    render json: {}
  end

  def string_notify
    Bugsnag.notify("handled string")
    render json: {}
  end
end
