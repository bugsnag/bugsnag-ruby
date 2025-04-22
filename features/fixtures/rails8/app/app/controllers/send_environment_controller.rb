class SendEnvironmentController < ActionController::Base
  protect_from_forgery

  def initializer
    Bugsnag.notify("handled string")
    render json: {}
  end
end
