class NotifyJob < ApplicationJob
  def perform
    Bugsnag.notify("Failed")
  end
end