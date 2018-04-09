class ReleaseStageController < ActionController::Base
  protect_from_forgery

  def index
    render json: {}
  end

  def default
    Bugsnag.notify("handled string")
    render json: {}
  end

  def after
    Bugsnag.configure do |conf|
      conf.release_stage = params[:stage]
    end
    Bugsnag.notify("handled string")
    render json: {}
  end
end
