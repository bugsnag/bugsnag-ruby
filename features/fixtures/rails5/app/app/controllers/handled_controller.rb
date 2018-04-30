class HandledController < ActionController::Base
  protect_from_forgery with: :exception

  def unthrown
    Bugsnag.notify(RuntimeError.new("handled unthrown error"))
    render json: {}
  end

  def thrown
    begin
      generate_unhandled_error
    rescue Exception => e
      Bugsnag.notify(e)
    end
    render json: {}
  end

  def string_notify
    Bugsnag.notify("handled string")
    render json: {}
  end
end
