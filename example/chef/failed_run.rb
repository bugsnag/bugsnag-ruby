chef_gem 'bugsnag' do
  compile_time false
end

require 'bugsnag'

Bugsnag.configure do |config|
  config.api_key = 'f35a2472bd230ac0ab0f52715bbdc65d'
  config.release_stage = 'production'
end

Chef.event_handler do
  on :run_failed do |exception|
    Bugsnag.notify exception
  end
end

package 'doesnotexist'
