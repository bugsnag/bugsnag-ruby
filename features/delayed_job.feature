Feature: Bugsnag detects errors in Delayed job workers

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I configure the bugsnag endpoint

Scenario: An unhandled RuntimeError sends a report with arguments
  Given I set environment variable "RUBY_VERSION" to "2.5"
  And I start the service "delayed_job"
  And I run the command "bundle exec rails runner 'TestModel.delay.fail_with_args(\"Test\")'" on the service "delayed_job"
  And I wait for 5 seconds
  Then I should receive a request
  And the request used the Ruby notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "unhandled" is true
  And the event "severity" is "error"
  And the event "context" is "TestModel.fail_with_args"
  And the event "severityReason.type" is "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" is "DelayedJob"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.job.class" equals "Delayed::Backend::ActiveRecord::Job"
  And the event "metaData.job.id" is not null
  And the event "metaData.job.attempts" equals "1 / 1"
  And the event "metaData.job.payload.display_name" equals "TestModel.fail_with_args"
  And the event "metaData.job.payload.method_name" equals "fail_with_args"
  And the payload field "events.0.metaData.job.payload.args" is an array with 1 element
  And the payload field "events.0.metaData.job.payload.args.0" equals "Test"

Scenario: A handled exception sends a report
  Given I set environment variable "RUBY_VERSION" to "2.5"
  And I start the service "delayed_job"
  And I run the command "bundle exec rails runner 'TestModel.delay.notify_with_args(\"Test\")'" on the service "delayed_job"
  And I wait for 5 seconds
  Then I should receive a request
  And the request used the Ruby notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "unhandled" is false
  And the event "severity" is "warning"
  And the event "context" is "TestModel.notify_with_args"
  And the event "severityReason.type" is "handledException"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.job.class" equals "Delayed::Backend::ActiveRecord::Job"
  And the event "metaData.job.id" is not null
  And the event "metaData.job.attempts" equals "1 / 1"
  And the event "metaData.job.payload.display_name" equals "TestModel.notify_with_args"
  And the event "metaData.job.payload.method_name" equals "notify_with_args"
  And the payload field "events.0.metaData.job.payload.args" is an array with 1 element
  And the payload field "events.0.metaData.job.payload.args.0" equals "Test"
