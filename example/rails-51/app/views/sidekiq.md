# Bugsnag Sidekiq demo

This route demonstrates how to use Bugsnag with Sidekiq.

While testing the examples open [your dashboard](https://app.bugsnag.com) in order to see the example errors and exceptions being received.

Make sure you have a Redis instance running that your test application can connect to before running these examples.

1. [Crash](/sidekiq/crash)
<br/>
    Raises an error within the framework, generating a report in the Bugsnag dashboard.

2. [Notify with data](/sidekiq/notify_data)
<br/>
    Same as `notify` but allows you to attach additional data within a `block`.  In this case we're adding information about the function being called to go into the `function` tab, and additional diagnostics as a `diagnostics` tab.
