Feature: Bugsnag raises errors in Mailman

Scenario: An unhandled RuntimeError sends a report
  Given I set environment variable "TARGET_EMAIL" to "emails/unhandled_error.eml"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I start the service "mailman"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event "unhandled" is true
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "Mailman"
  And the event "app.type" equals "mailman"
  And the exception "errorClass" equals "RuntimeError"

Scenario: A handled RuntimeError sends a report
  Given I set environment variable "TARGET_EMAIL" to "emails/handled_error.eml"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I start the service "mailman"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event "unhandled" is false
  And the event "severity" equals "warning"
  And the event "severityReason.type" equals "handledException"
  And the event "app.type" equals "mailman"
  And the exception "errorClass" equals "RuntimeError"
