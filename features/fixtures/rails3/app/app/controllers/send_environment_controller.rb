class SendEnvironmentController < ActionController::Base
  protect_from_forgery

  def index
    render json: {}
  end

  def initializer
    Bugsnag.notify("handled string")
    render json: {}
  end
end
