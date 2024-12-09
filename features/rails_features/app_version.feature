Feature: App version configuration

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
Scenario: App_version is nil by default
  Given I start the rails service
  When I navigate to the route "/app_version/default" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "app.version" is null

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
Scenario: Setting app_version in initializer works
  Given I set environment variable "BUGSNAG_APP_VERSION" to "1.0.0"
  And I start the rails service
  When I navigate to the route "/app_version/initializer" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "app.version" equals "1.0.0"

@rails3 @rails4 @rails5 @rails6 @rails7 @rails8
Scenario: Setting app_version after initializer works
  Given I start the rails service
  When I navigate to the route "/app_version/after?version=1.1.0" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "app.version" equals "1.1.0"
