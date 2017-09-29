# Bugsnag Sidekiq demo

This Sidekiq application demonstrates how to use Bugsnag with Sidekiq.
Further details about integrating Bugsnag with Sidekiq can be found [here.](https://docs.bugsnag.com/platforms/ruby/sidekiq/)

Install dependencies

```shell
bundle install
```

Sidekiq requires a datastore to run, this examples uses [redis](https://redis.io), installation instructions for which can be found [here](https://redis.io/topics/quickstart) and an official docker image can be found [here](https://hub.docker.com/_/redis/).

## Configuring Bugsnag and Sidekiq

Configure your `API_KEY` and any other configuration as detailed in the [available configuration options](https://docs.bugsnag.com/platforms/ruby/sidekiq/configuration-options/) by calling `Bugsnag.configure` and passing the options to the `configuration` object returned to a provided block:
  ```ruby
  Bugsnag.configure do |configuration|
    configuration.api_key = "YOUR_API_KEY"
  end
  ```

## Running the examples

Once the app is configured it can be run using two terminal windows.  In the first terminal the Sidekiq application will be started using:

```shell
bundle exec sidekiq -r ./sidekiq.rb
```

Once this is running, in the second terminal, you will need to open an interactive Ruby instance with the script loaded into it by running the command:

```shell
bundle exec irb -r ./sidekiq.rb
```

This will then allow the workers to be started via Ruby commands in the interactive Ruby instance.

Each of the examples can be run individually to verify the behaviour through the [Bugsnag dashboard](https://app.bugsnag.com):

1. Crash
<br/>
This example shows unhandled errors being captured by Bugsnag and a notification automatically being sent to the Bugsnag dashboard.  You can run this example with:
```ruby
Crash.perform_async
```

2. Crash with a callback
<br/>
This example is similar to the first, but by registering a callback before the error is caught we can attach additional information that can be viewed in the Bugsnag dashboard.  Run this example with:
```ruby
Callback.perform_async
```

3. Notify
<br/>
This example will send a notification without crashing the Resque worker.  This allows you to send notifications of handled errors to the Bugsnag dashboard.  Run this example with:
```ruby
Notify.perform_async
```

4. Notify with attached data
<br/>
This example is similar to the above, however adds additional data to the notification using a block.  Check out the `diagnostics` and `queue` tabs on the error in the dashboard.  Run this example with:
```ruby
Metadata.perform_async
```

5. Notify with a custom severity
<br/>
Finally, this example is similar to the previous, but sets a custom severity on the notification.  This will be reflected in the coloured circle shown alongside the event in the bugsnag dashboard.  Run this example with:
```ruby
Severity.perform_async
```
