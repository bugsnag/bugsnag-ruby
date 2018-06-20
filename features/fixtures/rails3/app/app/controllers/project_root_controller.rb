class ProjectRootController < ActionController::Base
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
      conf.project_root = '/test/root/here'
    end
    Bugsnag.notify("handled string")
    render json: {}
  end
end
