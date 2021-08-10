# Rails 4 doesn't automatically retry jobs, so this is a quick hack to allow us
# to run the same Rails 5/6 tests against Rails 4 by allowing one retry
$attempts = 0

class UnhandledJob < ApplicationJob
  rescue_from(RuntimeError) do |exception|
    raise exception if $attempts >= 2

    retry_job
  end

  def perform(*args, **kwargs)
    $attempts += 1

    raise 'Oh no!'
  end
end
