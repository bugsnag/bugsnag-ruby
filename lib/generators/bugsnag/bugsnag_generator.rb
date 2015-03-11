require 'rails/generators'
class BugsnagGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  argument :api_key, required: true, :desc => "required"

  gem "bugsnag"

  desc "Configures the bugsnag notifier with your API key"

  def create_initializer_file
    unless /^[a-f0-9]{32}$/ =~ api_key
      raise Thor::Error, "Invalid bugsnag notifier api key #{api_key.inspect}\nYou can find the api key on the Settings tab of https://bugsnag.com/"
    end

    initializer "bugsnag.rb" do
      <<-EOF
Bugsnag.configure do |config|
  config.api_key = #{api_key.inspect}
end
      EOF
    end

    puts <<-EOM
Bugsnag was installed successfully!

We've created an initializer at config/initializers/bugsnag.rb which contains
your Bugsnag API key. If you are using Rails 4.1+ you may wish to add this to
your config/secrets.yml file.
    EOM
  end
end
