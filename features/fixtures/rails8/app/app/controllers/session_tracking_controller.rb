class SessionTrackingController < ActionController::Base
  protect_from_forgery

  def initializer
    Bugsnag.session_tracker.send_sessions()
    render json: {}
  end

  def manual
    Bugsnag.start_session
    Bugsnag.session_tracker.send_sessions
    render json: {}
  end

  def multi_sessions
    (0...100).each { Bugsnag.start_session }
    Bugsnag.session_tracker.send_sessions
    render json: {}
  end
end
