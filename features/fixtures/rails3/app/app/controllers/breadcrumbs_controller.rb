class BreadcrumbsController < ActionController::Base
  def initialize
    @cache = ActiveSupport::Cache::MemoryStore.new
  end

  def handled
    Bugsnag.notify("Request breadcrumb")
    render json: {}
  end

  def sql_breadcrumb
    User.take
    Bugsnag.notify("SQL breadcrumb")
    render json: {}
  end

  def cache_read
    @cache.write('test', true)
    @cache.read('test')
    Bugsnag.notify("Cache breadcrumb")
    render json: {}
  end
end
