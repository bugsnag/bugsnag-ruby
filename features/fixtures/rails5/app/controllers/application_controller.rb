class ApplicationController < ActionController::Base
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

  def inline_notify_callback
    Bugsnag.notify(RuntimeError.new("handled error")) do |report|
    end
  end
end
