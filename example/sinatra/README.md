# Bugsnag Sinatra demo

This Sinatra application demonstrates how to use Bugsnag with Sinatra. Further details about integrating Bugsnag with Sidekiq can 

Install dependencies

```shell
bundle install
```

## Configuring Bugsnag and Sinatra

The `API_KEY` can be set in one of two ways:

1. Export the `API_KEY` as an environment variable, `BUGSNAG_API_KEY` to be used when running the server.

2. Configure the `API_KEY` and any other configuration as detailed in the [available configuration options](https://docs.bugsnag.com/platforms/ruby/rack/configuration-options/) by calling `Bugsnag.configure` and passing the options to the `configuration` object yielded to a provided block:
  ```ruby
  Bugsnag.configure do |configuration|
    configuration.api_key = "YOUR_API_KEY"
  end
  ```

Make sure the server is using the correct Bugsnag Rack middleware by activating it at the top of the file:
```ruby
use Bugsnag::Rack
```

Finally, to make sure exceptions are automatically cap[tured and notified in development or testing modes, ensure that the `raise_errors` option is set to `true`, and the `show_exceptions` option is set to `false`:
```ruby
set :raise_errors, true
set :show_exceptions, false
```

## Running the examples

Run the example using:

```shell
bundle exec rackup
```

Next, open your project's dashboard on Bugsnag, and go to the default server route.