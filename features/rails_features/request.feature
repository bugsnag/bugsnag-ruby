Feature: Request data

@rails3 @rails4 @rails5 @rails6 @rails7
Scenario: Request data is collected automatically
  Given I start the rails service
  When I navigate to the route "/unhandled/error?a=123&b=456" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the exception "errorClass" equals "NameError"
  And the exception "message" matches "^undefined local variable or method `generate_unhandled_error' for (#<|an instance of )UnhandledController"
  And the event "app.type" equals "rails"
  And the event "metaData.request.clientIp" is not null
  And the event "metaData.request.headers.Host" is not null
  And the event "metaData.request.headers.User-Agent" is not null
  And the event "metaData.request.headers.Version" is not null
  And the event "metaData.request.httpMethod" equals "GET"
  And the event "metaData.request.params.action" equals "error"
  And the event "metaData.request.params.controller" equals "unhandled"
  And the event "metaData.request.params.a" equals "123"
  And the event "metaData.request.params.b" equals "456"
  And the event "metaData.request.railsAction" equals "unhandled#error"
  And the event "metaData.request.referer" is null
  And the event "metaData.request.requestId" is not null
  And the event "metaData.request.url" ends with "/unhandled/error?a=123&b=456"

@rails3 @rails4 @rails5 @rails6 @rails7
Scenario: Request data can be modified in callbacks
  Given I set environment variable "ADD_REQUEST_ON_ERROR" to "true"
  And I start the rails service
  When I navigate to the route "/unhandled/error?a=123&b=456" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the exception "errorClass" equals "NameError"
  And the exception "message" matches "^undefined local variable or method `generate_unhandled_error' for (#<|an instance of )UnhandledController"
  And the event "app.type" equals "rails"
  And the event "metaData.request.something" equals "hello"
  And the event "metaData.request.params.another_thing" equals "hi"
  And the event "metaData.request.clientIp" is not null
  And the event "metaData.request.headers.Host" is not null
  And the event "metaData.request.headers.User-Agent" is not null
  And the event "metaData.request.headers.Version" is not null
  And the event "metaData.request.httpMethod" equals "GET"
  And the event "metaData.request.params.action" equals "error"
  And the event "metaData.request.params.controller" equals "unhandled"
  And the event "metaData.request.params.a" equals "123"
  And the event "metaData.request.params.b" equals "456"
  And the event "metaData.request.railsAction" equals "unhandled#error"
  And the event "metaData.request.referer" is null
  And the event "metaData.request.requestId" is not null
  And the event "metaData.request.url" ends with "/unhandled/error?a=123&b=456"
