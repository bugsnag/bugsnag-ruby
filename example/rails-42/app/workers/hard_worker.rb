class HardWorker
  include Sidekiq::Worker
  def perform(how_hard, how_long)
    puts "Workin' #{how_hard} #{how_long}"
    raise 'Uh oh!'
  end
end

#HardWorker.perform_async('bob', 5)
