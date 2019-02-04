class AppTypeController < ActionController::Base
  protect_from_forgery

  def default_handled
    raise RuntimeError.new ("Handled error")
  rescue Exception => e
    Bugsnag.notify(e)
    render json: {}
  end

  def default_unhandled
    raise RuntimeError.new ("Unhandled error")
  end

  def initializer
    Bugsnag.notify("handled string")
    render json: {}
  end

  def after
    Bugsnag.configure do |conf|
      conf.app_type = params[:type]
    end
    Bugsnag.notify("handled string")
    render json: {}
  end
end
