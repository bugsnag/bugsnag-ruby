class UnhandledJob < ApplicationJob
  self.queue_adapter = ENV['ACTIVE_JOB_QUEUE_ADAPTER'].to_sym

  def perform(*args, **kwargs)
    raise 'Oh no!'
  end
end
