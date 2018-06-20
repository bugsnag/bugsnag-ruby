class AppVersionController < ActionController::Base
  protect_from_forgery

  def index
    render json: {}
  end

  def default
    Bugsnag.notify("handled string")
    render json: {}
  end

  def initializer
    Bugsnag.notify("handled string")
    render json: {}
  end

  def after
    Bugsnag.configure do |conf|
      conf.app_version = params[:version]
    end
    Bugsnag.notify("handled string")
    render json: {}
  end
end
