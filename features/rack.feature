Feature: Bugsnag raises errors in Rack

Scenario: An unhandled RuntimeError sends a report
  Given I start the rack service
  When I navigate to the route "/unhandled" on the rack app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event "unhandled" is true
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "Rack"
  And the event "app.type" equals "rack"
  And the exception "errorClass" equals "RuntimeError"

Scenario: A handled RuntimeError sends a report
  Given I start the rack service
  When I navigate to the route "/handled" on the rack app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event "unhandled" is false
  And the event "severity" equals "warning"
  And the event "severityReason.type" equals "handledException"
  And the event "app.type" equals "rack"
  And the exception "errorClass" equals "RuntimeError"
