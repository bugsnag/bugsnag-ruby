require "../../lib/bugsnag"

Bugsnag.configure do |config|
    config.api_key = "8a6ef0388db46ab944e32ca99ccbfd68"
    config.endpoint = "localhost:8000"
    config.notify_release_stages = ["development", "production"]
end
use Bugsnag::Rack

run lambda { |env|
    puts Bugsnag.configuration.project_root
    if env["PATH_INFO"] =='/nonfatal'
      Bugsnag.notify(RuntimeError.new("Something broke"))
    elsif env["PATH_INFO"] =='/fatal'
      raise RuntimeError.new("Something broke")
    end
    
    [200, {'Content-Type'=>'text/html'}, '<html><head></head><body><h1>Bugsnag Rack Test App</h1><a href="/nonfatal">Non-Fatal Notify</a><br /><a href="/fatal">Fatal Notify</a></body></html>']
}