class SendCodeController < ActionController::Base
  protect_from_forgery

  def index
    render json: {}
  end

  def initializer
    Bugsnag.notify("handled string")
    render json: {}
  end

  def after
    Bugsnag.configure do |conf|
      conf.send_code = false
    end
    Bugsnag.notify("handled string")
    render json: {}
  end
end
