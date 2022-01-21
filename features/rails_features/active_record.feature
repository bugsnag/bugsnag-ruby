Feature: Active Record

@rails3 @rails4 @rails5 @rails6
Scenario: An unhandled error in a transaction callback will be delivered
  Given I start the rails service
  When I navigate to the route "/unhandled/error_in_active_record_callback" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event "unhandled" is true
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" equals "Oh no!"
  And the event "app.type" equals "rails"
  And the event "metaData.request.url" ends with "/unhandled/error_in_active_record_callback"
  And the event "severity" equals "error"

# The "raise_in_transactional_callbacks" config option only exists in Rails 4.2
@rails4
Scenario: An unhandled error in a transaction callback will be delivered when raise in transactional callbacks is false
  Given I set environment variable "RAISE_IN_TRANSACTIONAL_CALLBACKS" to "false"
  And I start the rails service
  When I navigate to the route "/unhandled/error_in_active_record_callback" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event "unhandled" is true
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" equals "Oh no!"
  And the event "app.type" equals "rails"
  And the event "metaData.request.url" ends with "/unhandled/error_in_active_record_callback"
  And the event "severity" equals "error"
