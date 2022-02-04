Feature: Send environment

@rails3 @rails4 @rails5 @rails6 @rails7
Scenario: Send_environment should send environment in handled errors when true
  Given I set environment variable "BUGSNAG_SEND_ENVIRONMENT" to "true"
  And I start the rails service
  When I navigate to the route "/send_environment/initializer" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" starts with "handled string"
  And the event "metaData.environment.REQUEST_METHOD" equals "GET"
  And the event "app.type" equals "rails"
