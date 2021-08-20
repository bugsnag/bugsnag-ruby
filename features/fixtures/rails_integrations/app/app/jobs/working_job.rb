class WorkingJob < ApplicationJob
  self.queue_adapter = ENV['ACTIVE_JOB_QUEUE_ADAPTER'].to_sym

  def perform
    do_stuff

    more_stuff

    success!
  end

  def do_stuff
    'beep boop'
  end

  def more_stuff
    'boop beep'
  end

  def success!
    'yay'
  end
end
