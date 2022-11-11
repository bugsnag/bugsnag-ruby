Feature: Bugsnag raises errors in Rack

Scenario: An unhandled RuntimeError sends a report
  Given I start the rack service
  When I navigate to the route "/unhandled?a=123&b=456" on the rack app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "Rack"
  And the event "app.type" equals "rack"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.request.body" is null
  And the event "metaData.request.clientIp" is not null
  And the event "metaData.request.cookies" is null
  And the event "metaData.request.headers.Host" is not null
  And the event "metaData.request.headers.User-Agent" is not null
  And the event "metaData.request.headers.Version" is not null
  And the event "metaData.request.httpMethod" equals "GET"
  And the event "metaData.request.httpVersion" matches "^HTTP/\d\.\d$"
  And the event "metaData.request.params.a" equals "123"
  And the event "metaData.request.params.b" equals "456"
  And the event "metaData.request.referer" is null
  And the event "metaData.request.url" ends with "/unhandled?a=123&b=456"

Scenario: A handled RuntimeError sends a report
  Given I start the rack service
  When I navigate to the route "/handled?a=123&b=456" on the rack app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is false
  And the event "severity" equals "warning"
  And the event "severityReason.type" equals "handledException"
  And the event "app.type" equals "rack"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.request.body" is null
  And the event "metaData.request.clientIp" is not null
  And the event "metaData.request.cookies" is null
  And the event "metaData.request.headers.Host" is not null
  And the event "metaData.request.headers.User-Agent" is not null
  And the event "metaData.request.headers.Version" is not null
  And the event "metaData.request.httpMethod" equals "GET"
  And the event "metaData.request.httpVersion" matches "^HTTP/\d\.\d$"
  And the event "metaData.request.params.a" equals "123"
  And the event "metaData.request.params.b" equals "456"
  And the event "metaData.request.referer" is null
  And the event "metaData.request.url" ends with "/handled?a=123&b=456"

Scenario: A POST request with form data sends a report with the parsed request body attached
  Given I start the rack service
  When I send a POST request to "/unhandled?a=123&b=456" in the rack app with the following form data:
    | name             | baba      |
    | favourite_letter | z         |
    | password         | password1 |
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "metaData.request.body.name" equals "baba"
  And the event "metaData.request.body.favourite_letter" equals "z"
  And the event "metaData.request.body.password" equals "[FILTERED]"
  And the event "metaData.request.clientIp" is not null
  And the event "metaData.request.cookies" is null
  And the event "metaData.request.headers.Host" is not null
  And the event "metaData.request.headers.User-Agent" is not null
  And the event "metaData.request.headers.Version" is not null
  And the event "metaData.request.httpMethod" equals "POST"
  And the event "metaData.request.httpVersion" matches "^HTTP/\d\.\d$"
  And the event "metaData.request.params.a" equals "123"
  And the event "metaData.request.params.b" equals "456"
  And the event "metaData.request.referer" is null
  And the event "metaData.request.url" ends with "/unhandled?a=123&b=456"

Scenario: A POST request with JSON sends a report with the parsed request body attached
  Given I start the rack service
  When I send a POST request to "/unhandled?a=123&b=456" in the rack app with the following JSON:
    | name             | baba      |
    | favourite_letter | z         |
    | password         | password1 |
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "metaData.request.body.name" equals "baba"
  And the event "metaData.request.body.favourite_letter" equals "z"
  And the event "metaData.request.body.password" equals "[FILTERED]"
  And the event "metaData.request.clientIp" is not null
  And the event "metaData.request.cookies" is null
  And the event "metaData.request.headers.Host" is not null
  And the event "metaData.request.headers.User-Agent" is not null
  And the event "metaData.request.headers.Version" is not null
  And the event "metaData.request.httpMethod" equals "POST"
  And the event "metaData.request.httpVersion" matches "^HTTP/\d\.\d$"
  And the event "metaData.request.params.a" equals "123"
  And the event "metaData.request.params.b" equals "456"
  And the event "metaData.request.referer" is null
  And the event "metaData.request.url" ends with "/unhandled?a=123&b=456"

Scenario: A request with cookies will be filtered out by default
  Given I start the rack service
  When I navigate to the route "/unhandled?a=123&b=456" on the rack app with these cookies:
    | a | b |
    | c | d |
    | e | f |
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "metaData.request.cookie" is null
  And the event "metaData.request.headers.Cookie" equals "[FILTERED]"
  And the event "metaData.request.clientIp" is not null
  And the event "metaData.request.headers.Host" is not null
  And the event "metaData.request.headers.User-Agent" is not null
  And the event "metaData.request.headers.Version" is not null
  And the event "metaData.request.httpMethod" equals "GET"
  And the event "metaData.request.httpVersion" matches "^HTTP/\d\.\d$"
  And the event "metaData.request.params.a" equals "123"
  And the event "metaData.request.params.b" equals "456"
  And the event "metaData.request.referer" is null
  And the event "metaData.request.url" ends with "/unhandled?a=123&b=456"

Scenario: A request with cookies and no matching filter will set cookies in metadata
  Given I set environment variable "BUGSNAG_METADATA_FILTERS" to '["password"]'
  And I start the rack service
  When I navigate to the route "/unhandled?a=123&b=456" on the rack app with these cookies:
    | a | b |
    | c | d |
    | e | f |
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "metaData.request.cookies.a" equals "b"
  And the event "metaData.request.cookies.c" equals "d"
  And the event "metaData.request.cookies.e" equals "f"
  And the event "metaData.request.headers.Cookie" equals "a=b;c=d;e=f"
  And the event "metaData.request.clientIp" is not null
  And the event "metaData.request.headers.Host" is not null
  And the event "metaData.request.headers.User-Agent" is not null
  And the event "metaData.request.headers.Version" is not null
  And the event "metaData.request.httpMethod" equals "GET"
  And the event "metaData.request.httpVersion" matches "^HTTP/\d\.\d$"
  And the event "metaData.request.params.a" equals "123"
  And the event "metaData.request.params.b" equals "456"
  And the event "metaData.request.referer" is null
  And the event "metaData.request.url" ends with "/unhandled?a=123&b=456"
