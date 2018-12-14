class BreadcrumbsController < ActionController::Base
  protect_from_forgery with: :exception

  def handled
    Bugsnag.notify("Request breadcrumb")
    render json: {}
  end

  def sql_breadcrumb
    User.take
    Bugsnag.notify("SQL breadcrumb")
    render json: {}
  end
end
