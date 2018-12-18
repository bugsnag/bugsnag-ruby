class ApplicationJob < ActiveJob::Base
  def perform
    Bugsnag.notify("Failed")
  end
end
