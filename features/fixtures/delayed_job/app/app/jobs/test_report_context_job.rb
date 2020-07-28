class TestReportContextJob < ApplicationJob
  queue_as :default

  def perform(*)
    raise "oh dear"
  end
end
