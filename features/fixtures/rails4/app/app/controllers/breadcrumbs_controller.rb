class BreadcrumbsController < ApplicationController
  def handled
    Bugsnag.notify("Request breadcrumb")
    render json: {}
  end

  def sql_breadcrumb
    User.where(:email => "foo")
    Bugsnag.notify("SQL breadcrumb")
    render json: {}
  end

  def active_job
    Thread.new { NotifyJob.perform_later }.join
    render json: {}
  end

  def cache_read
    Thread.new {
      Rails.cache.write('test', true)
      Rails.cache.read('test')
      Bugsnag.notify("Cache breadcrumb")
    }.join
    render json: {}
  end
end
