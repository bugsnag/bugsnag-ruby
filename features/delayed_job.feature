Feature: Bugsnag detects errors in Delayed job workers

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I configure the bugsnag endpoint
  And I generate the gem and put it in "delayed_job"

Scenario: An unhandled RuntimeError sends a report
  Given I set environment variable "RUBY_VERSION" to "2.5"
  And I start the service "delayed_job"
  And I run the command "bundle exec rails runner 'TestModel.delay.fail'" on the service "delayed_job"
  And I wait for 1 seconds
  Then I should receive a request
  And the request used the Ruby notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "unhandled" is true
  And the event "severity" is "error"
  And the event "context" is null
  And the event "severityReason.type" is "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" is "delayed_job"
  And the exception "errorClass" equals "RuntimeError"
  And the "file" of stack frame 0 equals "/usr/src/app.rb"
  And the "lineNumber" of stack frame 0 equals 33
  And the payload field "events.0.metaData.sidekiq" matches the JSON fixture in "features/fixtures/sidekiq/payloads/unhandled_metadata_ca_<created_at_present>.json"
  And the event "metaData.sidekiq.msg.created_at" is a parsable timestamp in seconds
  And the event "metaData.sidekiq.msg.enqueued_at" is a parsable timestamp in seconds
