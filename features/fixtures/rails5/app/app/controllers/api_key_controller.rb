class ApiKeyController < ActionController::Base
  protect_from_forgery

  def environment
    Bugsnag.notify("handled string")
    render json: {}
  end

  def changing
    Bugsnag.configure do |conf|
      conf.api_key = params[:api_key]
    end
    Bugsnag.notify("handled string")
    render json: {}
  end
end
