require "bugsnag"

namespace :bugsnag do
  desc "Notify Bugsnag of a new deploy."
  task :deploy => :load do
    api_key = ENV["BUGSNAG_API_KEY"]
    release_stage = ENV["BUGSNAG_RELEASE_STAGE"]
    app_version = ENV["BUGSNAG_APP_VERSION"]
    revision = ENV["BUGSNAG_REVISION"]
    repository = ENV["BUGSNAG_REPOSITORY"]
    branch = ENV["BUGSNAG_BRANCH"]

    Rake::Task["load"].invoke unless api_key

    Bugsnag::Deploy.notify({
      :api_key => api_key,
      :release_stage => release_stage,
      :app_version => app_version,
      :revision => revision,
      :repository => repository,
      :branch => branch
    })
  end

  desc "Send a test exception to Bugsnag."
  task :test_exception => :load do
    begin
      raise RuntimeError.new("Bugsnag test exception")
    rescue => e
      Bugsnag.notify(e, {:context => "rake#test_exception"})
    end
  end

  desc "Show the bugsnag middleware stack"
  task :middleware => :load do
    Bugsnag.configuration.middleware.each {|m| puts m.to_s}
  end
end

task :load do
  begin
    Rake::Task["environment"].invoke
  rescue
  end
end
