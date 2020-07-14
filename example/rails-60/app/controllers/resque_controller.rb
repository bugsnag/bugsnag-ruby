class ResqueController < ActionController::Base
  layout "application"

  def crash
    Resque.enqueue(ResqueWorkers::Crash)
  end

  def metadata
    Resque.enqueue(ResqueWorkers::Metadata)
  end

  def callbacks
    Resque.enqueue(ResqueWorkers::Callback)
  end
end
