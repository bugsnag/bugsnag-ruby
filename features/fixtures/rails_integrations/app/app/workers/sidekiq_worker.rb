class SidekiqWorker
  include Sidekiq::Worker

  def perform(*args)
    raise 'bad things'
  end
end
