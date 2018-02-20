# Bugsnag Rack demo

This Rack application demonstrates how to use Bugsnag with Rack.
Further details about integrating Bugsnag with Rack applications can be found [here.](https://docs.bugsnag.com/platforms/ruby/rack/)

Install dependencies

```shell
bundle install
```

## Configuring Bugsnag and Rack

1. Set up the Bugsnag configuration in ```server.rb``` by calling `Bugsnag.configure` and setting your API key and any other options [as detailed in the configuration options](https://docs.bugsnag.com/platforms/ruby/rack/configuration-options/):
  ```ruby
  Bugsnag.configure do |config|
    config.api_key = 'YOUR_API_KEY'
  end
  ```

2. Alternatively the API key can be set by exported it as a `BUGSNAG_API_KEY` environment variable.

3. To enable automatic notification in the Rack server the server object must be wrapped in an instance of `Bugsnag::Rack` which is then passed to the `Rack::Server` to be started:
  ```ruby
  server = BugsnagDemo.new
  wrapped_app = Bugsnag::Rack.new(server)
  Rack::Server.start(app: wrapped_app)  
  ```

4. Ensure that `ShowExceptions` is set to false, otherwise notifications will not be sent while in development mode.

## Running the example

Run the example using:

```shell
bundle exec ruby server.rb 
```

Once the server is running head to the default path for more information on Bugsnag logging examples.