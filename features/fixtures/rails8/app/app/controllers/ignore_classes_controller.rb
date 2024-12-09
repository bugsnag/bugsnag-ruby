class IgnoredError < RuntimeError
end

class IgnoreClassesController < ActionController::Base
  protect_from_forgery

  def initializer
    Bugsnag.notify(IgnoredError.new)
    render json: {}
  end

  def after
    Bugsnag.configure do |conf|
      conf.ignore_classes << Kernel.const_get(params[:ignore])
    end
    Bugsnag.notify(IgnoredError.new)
    render json: {}
  end
end
