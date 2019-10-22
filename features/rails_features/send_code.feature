Feature: Send code

@rails3 @rails4 @rails5 @rails6
Scenario: Send_code can be updated in an initializer
  Given I set environment variable "BUGSNAG_SEND_CODE" to "false"
  And I start the rails service
  When I navigate to the route "/send_code/initializer" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event "exceptions.0.stacktrace.0.code" is null

@rails3 @rails4 @rails5 @rails6
Scenario: Send_code can be updated after an initializer
  Given I start the rails service
  When I navigate to the route "/send_code/after" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event "exceptions.0.stacktrace.0.code" is null
