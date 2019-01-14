class SessionTrackingController < ActionController::Base
  protect_from_forgery

  def index
    render json: {}
  end

  def initializer
    Bugsnag.session_tracker.send_sessions()
    render json: {}
  end

  def manual
    Bugsnag.start_session
    Bugsnag.session_tracker.send_sessions
    render json: {}
  end

  def hundred
    (0...100).each { Bugsnag.start_session }
    Bugsnag.session_tracker.send_sessions
    render json: {}
  end
end
