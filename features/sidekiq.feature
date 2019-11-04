Feature: Bugsnag raises errors in Sidekiq workers

Scenario: An unhandled RuntimeError sends a report
  Given I run the service "sidekiq" with the command "bundle exec rake sidekiq_tests:unhandled_error"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event "unhandled" is true
  And the event "severity" equals "error"
  And the event "context" equals "UnhandledError@default"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "Sidekiq"
  And the exception "errorClass" equals "RuntimeError"
  And the "file" of stack frame 0 equals "/app/app.rb"
  And the "lineNumber" of stack frame 0 equals 33
  And the payload field "events.0.metaData.sidekiq" matches the appropriate unhandled JSON fixture
  And the event "metaData.sidekiq.msg.created_at" is a parsable timestamp in seconds
  And the event "metaData.sidekiq.msg.enqueued_at" is a parsable timestamp in seconds

Scenario: A handled RuntimeError can be notified
  Given I run the service "sidekiq" with the command "bundle exec rake sidekiq_tests:handled_error"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event "unhandled" is false
  And the event "context" equals "HandledError@default"
  And the event "severity" equals "warning"
  And the event "severityReason.type" equals "handledException"
  And the exception "errorClass" equals "RuntimeError"
  And the payload field "events.0.metaData.sidekiq" matches the appropriate handled JSON fixture
  And the event "metaData.sidekiq.msg.created_at" is a parsable timestamp in seconds
  And the event "metaData.sidekiq.msg.enqueued_at" is a parsable timestamp in seconds