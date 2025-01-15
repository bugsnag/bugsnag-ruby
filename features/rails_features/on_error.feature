Feature: On error callbacks

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
Scenario: Rails on_error works on handled errors
  Given I set environment variable "ADD_ON_ERROR" to "true"
  And I start the rails service
  When I navigate to the route "/handled/unthrown" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" starts with "handled unthrown error"
  And the event "unhandled" is false
  And the event "app.type" equals "rails"
  And the event "metaData.request.url" ends with "/handled/unthrown"
  And the event "metaData.on_error.source" equals "on_error handled"

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
Scenario: Rails on_error works on unhandled errors
  Given I set environment variable "ADD_ON_ERROR" to "true"
  And I start the rails service
  When I navigate to the route "/unhandled/error" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the exception "errorClass" equals "NameError"
  And the exception "message" matches "^undefined local variable or method ('|`)generate_unhandled_error' for (#<|an instance of )UnhandledController"
  And the event "unhandled" is true
  And the event "app.type" equals "rails"
  And the event "metaData.request.url" ends with "/unhandled/error"
  And the event "metaData.on_error.source" equals "on_error unhandled"
