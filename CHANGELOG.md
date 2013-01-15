Changelog
=========

1.2.11
------
-   Send rails version with exceptions
-   Protect against nil params object when errors happen in rack

1.2.10
------
-   Added Rack HTTP method (GET, POST, etc) to request tab

1.2.9
-----
-   Fixed an issue with Warden userIds not being reported properly.

1.2.8
-----
-   Added `disable` method to Bugsnag middleware, allows you to force-disable
    built-in Bugsnag middleware.

1.2.7
-----
-   Protect against rare exception-unwrapping infinite loop 
    (only in some exceptions using the `original_exception` pattern)

1.2.6
-----
-   Fix for rails 2 request data extraction
-   Deploy environment customization support (thanks coop)
-   Ensure Bugsnag rails 3 middleware runs before initializers

1.2.5
-----
-   Show a warning if no release_stage is set when delivering exceptions
-   Require resque plugin in a safer way

1.2.4
-----
-   Automatically set the release_stage in a safer way on rack/rails

1.2.3
-----
-   Re-add support for sending bugsnag notifications via resque

1.2.2
-----
-   Add rspec tests for rack middleware

1.2.1
-----
-   Fix a bug where before/after hooks were not being fired

1.2.0
-----
-   Added Bugsnag Middleware and callback, easier ways to add custom data to
    your exceptions
-   Added automatic Sidekiq integration
-   Added automatic Devise integration
-   Comprehensive rspec tests

1.1.5
-----
-   Fix minor internal version number parsing bug

1.1.4
-----
-   Move Bugsnag rack middleware later in the middleware stack, fixes 
    issue where development exception may not have been delivered

1.1.3
-----
-   Fix multi_json conflict with rails 3.1
-   Make bugsnag_request_data public for easier EventMachine integration
    (thanks fblee)

1.1.2
-----
-   Fix multi_json gem dependency conflicts

1.1.1
-----
-   Capistrano deploy tracking support
-   More reliable project_root detection for non-rails rack apps
-   Support for sending test exceptions from rake (`rake bugsnag:test_exception`)

1.1.0
-----
-   First public release