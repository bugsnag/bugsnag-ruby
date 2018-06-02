require './app/workers/resque_workers'

class ResqueController < ActionController::Base
  protect_from_forgery with: :exception

  def index
    @text = File.read(File.expand_path('app/views/resque.md'))
  end

  def crash
    Resque.enqueue(ResqueWorkers::Crash)
    @text = "The crash task has been queued.  This can be run using the `QUEUE=crash bundle exec rake resque:work` command"
  end

  def metadata
    Resque.enqueue(ResqueWorkers::Metadata)
    @text = "The metadata task has been queued.  This can be run using the `QUEUE=metadata bundle exec rake resque:work` command"
  end

  def callbacks
    Resque.enqueue(ResqueWorkers::Callback)
    @text = "The callback task has been queued.  This can be run using the `QUEUE=callback bundle exec rake resque:work` command"
  end
end
