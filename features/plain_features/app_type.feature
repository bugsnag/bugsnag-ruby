Feature: App type configuration option

Scenario: The App type configuration option can be set
  Given I set environment variable "BUGSNAG_APP_TYPE" to "test_app"
  When I run the service "plain-ruby" with the command "bundle exec ruby configuration/send_handled.rb"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "app.type" equals "test_app"
