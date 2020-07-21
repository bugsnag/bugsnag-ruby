# Bugsnag Rails v5.1 demo

This application demonstrates the use of Bugsnag with the Rails web framework.

For other examples within this application see the following pages:

- [Sidekiq](/sidekiq)
- [Resque](/resque)
- [Que](/que)

While testing the examples open [your dashboard](https://app.bugsnag.com) in order to see the example errors and exceptions being received.

1. [Crash](/crash)
<br/>
    Raises an error within the framework, generating a report in the Bugsnag dashboard.

2. [Notify](/notify)
<br/>
    Sends Bugsnag a report on demand using `bugsnag.notify`.  Allows details of handled errors or information to be sent to the Bugsnag dashboard without crashing your code.

3. [Notify with data](/notify_data)
<br/>
    Same as `notify` but allows you to attach additional data within a `block`. In this case we're adding additional diagnostics as a `diagnostics` tab.

4. [Set the severity](/notify_severity)
<br/>
    This uses the same mechanism as adding meta-data, but allows you to set he `severity` when notifying Bugsnag of the error.  Valid severities are `error`, `warning`, and `info`.  Have a look on the dashboard to see the difference in these severities.
