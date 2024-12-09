Feature: Auto notify

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
Scenario: Auto_notify set to false in the initializer prevents unhandled error sending
  Given I set environment variable "BUGSNAG_AUTO_NOTIFY" to "false"
  And I start the rails service
  When I navigate to the route "/auto_notify/unhandled" on the rails app
  Then I should receive no requests

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
Scenario: Auto_notify set to false in the initializer still sends handled errors
  Given I set environment variable "BUGSNAG_AUTO_NOTIFY" to "false"
  And I start the rails service
  When I navigate to the route "/auto_notify/handled" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is false
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" starts with "handled string"
  And the event "app.type" equals "rails"
  And the event "metaData.request.url" ends with "/auto_notify/handled"

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
Scenario: Auto_notify set to false after the initializer prevents unhandled error sending
  Given I start the rails service
  When I navigate to the route "/auto_notify/unhandled_after" on the rails app
  Then I should receive no requests

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
Scenario: Auto_notify set to false after the initializer still sends handled errors
  Given I start the rails service
  When I navigate to the route "/auto_notify/handled_after" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" starts with "handled string"
  And the event "unhandled" is false
  And the event "metaData.request.url" ends with "/auto_notify/handled_after"
  And the event "app.type" equals "rails"
