# Bugsnag Resque demo

This Resque application demonstrates how to use Bugsnag with Resque.
Further details about integrating Bugsnag with Resque can be found [here.](https://docs.bugsnag.com/platforms/ruby/other/)

Install dependencies

```shell
bundle install
```

## Configuring Bugsnag and Resque

Configure your `API_KEY` and any other configuration as detailed in the [available configuration options](https://docs.bugsnag.com/platforms/ruby/other/configuration-options/) by calling `Bugsnag.configure` and passing the options to the `configuration` object returned to a provided block:
  ```ruby
  Bugsnag.configure do |configuration|
    configuration.api_key = "YOUR_API_KEY"
  end
  ```

In the applications ```Rakefile``` ensure that the `bugsnag/integrations/rake` middleware is loaded to automatically handled any errors.

## Running the examples

Each of the examples can be run individually to verify the behaviour through the [Bugsnag dashboard](https://app.bugsnag.com):

1. Crash
<br/>
This example shows unhandled errors being captured by Bugsnag and a notification automatically being sent to the Bugsnag dashboard.  You can run this example with:
```shell
QUEUE=crash bundle exec rake resque:work
```

2. Crash with a callback
<br/>
This example is similar to the first, but by registering a callback before the error is caught we can attach additional information that can be viewed in the Bugsnag dashboard.  Run this example with:
```shell
QUEUE=callback bundle exec rake resque:work
```

3. Notify
<br/>
This example will send a notification without crashing the Resque worker.  This allows you to send notifications of handled errors to the Bugsnag dashboard.  Run this example with:
```shell
QUEUE=notify bundle exec rake resque:work
```

4. Notify with attached data
<br/>
This example is similar to the above, however adds additional data to the notification using a block.  Check out the `diagnostics` and `queue` tabs on the error in the dashboard.  Run this example with:
```shell
QUEUE=data bundle exec rake resque:work
```

5. Notify with a custom severity
<br/>
Finally, this example is similar to the previous, but sets a custom severity on the notification.  This will be reflected in the coloured circle shown alongside the event in the bugsnag dashboard.  Run this example with:
```shell
QUEUE=severity bundle exec rake resque:work
```
