class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def index
    render json: {}
  end

  def unhandled
    generate_unhandled_error
  end

  def handled_unthrown
    Bugsnag.notify(RuntimeError.new("handled unthrown error"))
    render json: {}
  end

  def handled_thrown
    begin
      unhandled
    rescue Exception => e
      Bugsnag.notify(e)
    end
    render json: {}
  end
end
