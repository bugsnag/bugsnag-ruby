require "bugsnag"

namespace :bugsnag do
  desc "Send a test exception to Bugsnag."
  task :test_exception => :load do
    begin
      raise RuntimeError.new("Bugsnag test exception")
    rescue => e
      Bugsnag.auto_notify(e, {
        :type => "middleware",
        :attributes => {
          :name => "rake"
        }
      }) do |report|
        report.context = "rake#test_exception"
      end
    end
  end
end

task :load do
  begin
    Rake::Task["environment"].invoke
  rescue
  end
end
