Feature: Bugsnag raises errors in Sidekiq workers

Scenario: An unhandled RuntimeError sends a report
  Given I run the service "sidekiq" with the command "timeout 5 bundle exec rake sidekiq_tests:unhandled_error"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "severity" equals "error"
  And the event "context" equals "UnhandledError@default"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "Sidekiq"
  And the event "app.type" equals "sidekiq"
  And the exception "errorClass" equals "RuntimeError"
  And the "file" of stack frame 0 equals "/app/app.rb"
  And the "lineNumber" of stack frame 0 equals 44
  And the event "metaData.sidekiq" matches the appropriate Sidekiq unhandled payload
  And the event "metaData.sidekiq.msg.created_at" is a parsable timestamp in seconds
  And the event "metaData.sidekiq.msg.enqueued_at" is a parsable timestamp in seconds
  And the event "metaData.config.delivery_method" equals "thread_queue"

Scenario: A handled RuntimeError can be notified
  Given I run the service "sidekiq" with the command "timeout 5 bundle exec rake sidekiq_tests:handled_error"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is false
  And the event "context" equals "HandledError@default"
  And the event "severity" equals "warning"
  And the event "severityReason.type" equals "handledException"
  And the event "app.type" equals "sidekiq"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.sidekiq" matches the appropriate Sidekiq handled payload
  And the event "metaData.sidekiq.msg.created_at" is a parsable timestamp in seconds
  And the event "metaData.sidekiq.msg.enqueued_at" is a parsable timestamp in seconds
  And the event "metaData.config.delivery_method" equals "thread_queue"

Scenario: Synchronous delivery can be used
  Given I set environment variable "BUGSNAG_DELIVERY_METHOD" to "synchronous"
  And I run the service "sidekiq" with the command "timeout 5 bundle exec rake sidekiq_tests:handled_error"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is false
  And the event "context" equals "HandledError@default"
  And the event "severity" equals "warning"
  And the event "severityReason.type" equals "handledException"
  And the event "app.type" equals "sidekiq"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.sidekiq" matches the appropriate Sidekiq handled payload
  And the event "metaData.sidekiq.msg.created_at" is a parsable timestamp in seconds
  And the event "metaData.sidekiq.msg.enqueued_at" is a parsable timestamp in seconds
  And the event "metaData.config.delivery_method" equals "synchronous"
