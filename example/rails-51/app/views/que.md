# Bugsnag Que demo

This route demonstrates how to use Bugsnag with Que.

While testing the examples open [your dashboard](https://app.bugsnag.com) in order to see the example errors and exceptions being received.

Make sure you have a PostgreSQL instance running that your test application can connect to before running these examples.

1. [Crash](/que/crash)
<br/>
    Raises an error within the framework, generating a report in the Bugsnag dashboard.

2. [Crash and use callbacks](/que/crash_with_callback)
<br/>
    Raises an exception within the framework, but with additional data attached to the report.  By registering a callback before the error occurs useful data can be attached as a tab in the Bugsnag dashboard.