# Bugsnag Rescue demo

This route demonstrates how to use Bugsnag with Rescue.

While testing the examples open [your dashboard](https://app.bugsnag.com) in order to see the example errors and exceptions being received.

Make sure you have a Redis instance running that your test application can connect to before running these examples.

While each queue can be run individually, to run Resque so that it automatically executes each task, use:

```shell
QUEUE=crash,callback,metadata bundle exec rake resque:work
```

1. [Crash](/resque/crash)
<br/>
    Raises an error within the framework, generating a report in the Bugsnag dashboard.

2. [Crash and use callbacks](/resque/crash_with_callback)
<br/>
    Raises an exception within the framework, but with additional data attached to the report.  By registering a callback before the error occurs useful data can be attached as a tab in the Bugsnag dashboard.

3. [Notify with data](/resque/notify_data)
<br/>
    Same as `notify` but allows you to attach additional data within a `block`, similar to the `before_notify_callbacks` example above.  In this case we're adding information about the queue to go into the `queue` tab, and additional diagnostics as a `diagnostics` tab.