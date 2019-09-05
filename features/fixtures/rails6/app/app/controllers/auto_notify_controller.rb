class AutoNotifyController < ActionController::Base
  protect_from_forgery

  def unhandled
    generate_unhandled_error
  end

  def handled
    Bugsnag.notify("handled string")
    render json: {}
  end

  def unhandled_after
    Bugsnag.configure do |conf|
      conf.auto_notify = false
    end
    generate_unhandled_error
  end

  def handled_after
    Bugsnag.configure do |conf|
      conf.auto_notify = false
    end
    Bugsnag.notify("handled string")
    render json: {}
  end
end
