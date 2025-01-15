Feature: Unhandled exceptions support

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
Scenario: Unhandled RuntimeError
  Given I start the rails service
  When I navigate to the route "/unhandled/error" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the exception "errorClass" equals "NameError"
  And the exception "message" matches "^undefined local variable or method ('|`)generate_unhandled_error' for (#<|an instance of )UnhandledController"
  And the event "app.type" equals "rails"
  And the event "metaData.request.url" ends with "/unhandled/error"
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "Rack"
