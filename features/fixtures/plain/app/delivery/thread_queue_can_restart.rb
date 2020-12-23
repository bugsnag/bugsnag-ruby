require "set"
require "./app"

configure_basics

$thread_ids = Set.new

class ThreadIdReporter
  # Because we don't serialise reports until they are about to be sent, this
  # will run in a separate thread for each notify if the thread_queue has restarted
  def to_s
    $thread_ids << Thread.current.object_id

    $thread_ids.length.to_s
  end
end

Bugsnag.configure do |config|
  config.delivery_method = :thread_queue

  config.add_on_error(proc do |report|
    report.add_tab(:thread_info, { number_of_threads: ThreadIdReporter.new })
  end)
end

Bugsnag.notify("this was handled")

raise "this was unhandled"
