require './app/workers/sidekiq_workers'

class SidekiqController < ActionController::Base
  protect_from_forgery with: :exception

  def index
    @text = File.read(File.expand_path('app/views/sidekiq.md'))
  end

  def crash
    SidekiqWorkers::CrashWorker.perform_async
    @text = "Sidekiq is performing a task that will crash, so check your dashboard for the result!"
  end

  def metadata
    SidekiqWorkers::MetadataWorker.perform_async
    @text = "Sidekiq is performing a task that will notify an error with some metadata without crashing.
    Check out your dashboard!"
  end
end
