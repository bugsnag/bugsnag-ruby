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
    NotifyJob.perform_later
    render json: {}
  end

  def cache_read
    Rails.cache.write('test', true)
    Rails.cache.read('test')
    Bugsnag.notify("Cache breadcrumb")
    render json: {}
  end
end
