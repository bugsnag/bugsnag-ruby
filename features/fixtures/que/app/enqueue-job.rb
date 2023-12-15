require_relative "setup-que"

query = <<-SQL
SELECT EXISTS (
  SELECT FROM pg_tables WHERE tablename  = 'que_jobs'
) AS que_jobs_exists
SQL

Timeout::timeout(10) do
  loop do
    break if $connection.exec(query)[0]["que_jobs_exists"] == "t"

    sleep 0.1
  end
end

case ARGV[0]
when "unhandled"
  UnhandledJob.enqueue
when "handled"
  HandledJob.enqueue
end
