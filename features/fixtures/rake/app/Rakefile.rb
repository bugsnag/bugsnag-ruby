require 'bugsnag/integrations/rake'

Bugsnag.configure do |config|
  puts "Configuring `api_key` to #{ENV['BUGSNAG_API_KEY']}"
  config.api_key = ENV['BUGSNAG_API_KEY']
  puts "Configuring `endpoint` to #{ENV['BUGSNAG_ENDPOINT']}"
  config.endpoint = ENV['BUGSNAG_ENDPOINT']
end

task :unhandled do
  raise 'Unhandled error'
end

task :handled do
  begin
    raise 'Handled error'
  rescue StandardError => e
    Bugsnag.notify(e)
  end
end
