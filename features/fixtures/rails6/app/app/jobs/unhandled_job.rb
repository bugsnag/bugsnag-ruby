class UnhandledJob < ApplicationJob
  retry_on RuntimeError, wait: 1.second, attempts: 2

  def perform(*args, **kwargs)
    raise 'Oh no!'
  end
end
