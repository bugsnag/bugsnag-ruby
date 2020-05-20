require './app/workers/sidekiq_workers'

class SidekiqController < ActionController::Base
  layout "application"

  def crash
    SidekiqWorkers::CrashWorker.perform_async
  end

  def metadata
    SidekiqWorkers::MetadataWorker.perform_async
  end

  def callbacks
    SidekiqWorkers::CallbackWorker.perform_async
  end
end
