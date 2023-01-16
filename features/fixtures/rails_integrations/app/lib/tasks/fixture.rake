namespace :fixture do
  task queue_unhandled_job: [:environment] do
    UnhandledJob.perform_later(1, yes: true)
  end

  task queue_working_job: [:environment] do
    WorkingJob.perform_later
  end

  task queue_resque_job: [:environment] do
    Resque.enqueue(ResqueWorker, 123, "abc", [7, 8, 9], x: true, y: false)
  end
end
