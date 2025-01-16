Feature: Rails handled errors

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
Scenario: Unhandled RuntimeError
  Given I start the rails service
  When I navigate to the route "/handled/unthrown" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is false
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" starts with "handled unthrown error"
  And the event "app.type" equals "rails"
  And the event "metaData.request.url" ends with "/handled/unthrown"
  And the event "severity" equals "warning"
  And the event "severityReason.type" equals "handledException"

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
Scenario: Thrown handled NameError
  Given I start the rails service
  When I navigate to the route "/handled/thrown" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the exception "errorClass" equals "NameError"
  And the exception "message" matches "^undefined local variable or method ('|`)generate_unhandled_error' for (#<|an instance of )HandledController"
  And the event "unhandled" is false
  And the event "metaData.request.url" ends with "/handled/thrown"
  And the event "app.type" equals "rails"
  And the event "severity" equals "warning"
  And the event "severityReason.type" equals "handledException"

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
Scenario: Manual string notify
  Given I start the rails service
  When I navigate to the route "/handled/string_notify" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" starts with "handled string"
  And the event "unhandled" is false
  And the event "metaData.request.url" ends with "/handled/string_notify"
  And the event "app.type" equals "rails"

