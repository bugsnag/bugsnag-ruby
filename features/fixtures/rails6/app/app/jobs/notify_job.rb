class NotifyJob < ApplicationJob
  def perform(*args, **kwargs)
    Bugsnag.notify("Failed")
  end
end
