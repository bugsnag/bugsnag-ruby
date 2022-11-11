Feature: Bugsnag raises errors in Rake

Scenario: An unhandled RuntimeError sends a report
  Given I run the service "rake" with the command "bundle exec rake unhandled"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "Rake"
  And the event "app.type" equals "rake"
  And the exception "errorClass" equals "RuntimeError"

Scenario: A handled RuntimeError sends a report
  Given I run the service "rake" with the command "bundle exec rake handled"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is false
  And the event "severity" equals "warning"
  And the event "severityReason.type" equals "handledException"
  And the event "app.type" equals "rake"
  And the exception "errorClass" equals "RuntimeError"
