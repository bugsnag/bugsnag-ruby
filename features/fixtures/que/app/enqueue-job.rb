require_relative "setup-que"

case ARGV[0]
when "unhandled"
  UnhandledJob.enqueue
when "handled"
  HandledJob.enqueue
end
