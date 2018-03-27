class ApplicationController < ActionController::Base
  protect_from_forgery

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
end
