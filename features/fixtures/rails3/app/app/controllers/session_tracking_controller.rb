class SessionTrackingController < ActionController::Base
  protect_from_forgery

  def index
    render json: {}
  end

  def initializer
    Bugsnag.session_tracker.send_sessions()
    render json: {}
  end

  def after
    Bugsnag.configure do |conf|
      conf.auto_capture_sessions = true
    end
    Bugsnag.session_tracker.send_sessions()
    render json: {}
  end
end
