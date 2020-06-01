Feature: App type configuration

@rails3 @rails4 @rails5 @rails6
Scenario: Setting app_type in initializer works
  Given I set environment variable "BUGSNAG_APP_TYPE" to "custom_app_type"
  And I start the rails service
  When I navigate to the route "/app_type/initializer" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" starts with "handled string"
  And the event "metaData.request.url" ends with "/app_type/initializer"
  And the event "app.type" equals "custom_app_type"

@rails3 @rails4 @rails5 @rails6
Scenario: Changing app_type after initializer works
  Given I start the rails service
  When I navigate to the route "/app_type/after?type=maze_after_initializer" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" starts with "handled string"
  And the event "metaData.request.url" ends with "/app_type/after?type=maze_after_initializer"
  And the event "app.type" equals "maze_after_initializer"
