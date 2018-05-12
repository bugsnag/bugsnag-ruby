Feature: Bugsnag raises errors in Sidekiq workers

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

Scenario Outline: An unhandled RuntimeError sends a report
  And I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "SIDEKIQ_VERSION" to "<sidekiq_version>"
  And I start the service "sidekiq"
  And I run the command "bundle exec ruby initializers/UnhandledError.rb" on the service "sidekiq"
  And I wait for 1 seconds
  Then I should receive a request
  And the request used the Ruby notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "unhandled" is true
  And the event "severity" is "error"
  And the event "severityReason.type" is "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" is "Sidekiq"
  And the exception "errorClass" equals "RuntimeError"
  And the "file" of stack frame 0 equals "/usr/src/app.rb"
  And the "lineNumber" of stack frame 0 equals 33
  And the payload field "events.0.metaData.sidekiq" matches the JSON fixture in "features/fixtures/sidekiq/payloads/unhandled_metadata_ca_<created_at_present>.json"
  And the event "metaData.sidekiq.msg.created_at" is a parsable timestamp in seconds
  And the event "metaData.sidekiq.msg.enqueued_at" is a parsable timestamp in seconds

  Examples:
  | ruby version | sidekiq_version | created_at_present |
  | 1.9.3        | '~> 2'          | false              |
  | 2.0          | '~> 2'          | false              |
  | 2.0          | '~> 3'          | true               |
  | 2.1          | '~> 2'          | false              |
  | 2.1          | '~> 3'          | true               |
  | 2.2          | '~> 2'          | false              |
  | 2.2          | '~> 3'          | true               |
  | 2.2          | '~> 4'          | true               |
  | 2.2          | '~> 5'          | true               |
  | 2.3          | '~> 2'          | false              |
  | 2.3          | '~> 3'          | true               |
  | 2.3          | '~> 4'          | true               |
  | 2.3          | '~> 5'          | true               |
  | 2.4          | '~> 2'          | false              |
  | 2.4          | '~> 3'          | true               |
  | 2.4          | '~> 4'          | true               |
  | 2.4          | '~> 5'          | true               |
  | 2.5          | '~> 2'          | false              |
  | 2.5          | '~> 3'          | true               |
  | 2.5          | '~> 4'          | true               |
  | 2.5          | '~> 5'          | true               |

Scenario Outline: A handled RuntimeError can be notified
  And I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "SIDEKIQ_VERSION" to "<sidekiq_version>"
  And I start the service "sidekiq"
  And I run the command "bundle exec ruby initializers/HandledError.rb" on the service "sidekiq"
  And I wait for 1 seconds
  Then I should receive a request
  And the request used the Ruby notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "unhandled" is false
  And the event "severity" is "warning"
  And the event "severityReason.type" is "handledException"
  And the exception "errorClass" equals "RuntimeError"
  And the "file" of stack frame 0 equals "/usr/src/app.rb"
  And the "lineNumber" of stack frame 0 equals 24
  And the payload field "events.0.metaData.sidekiq" matches the JSON fixture in "features/fixtures/sidekiq/payloads/handled_metadata_ca_<created_at_present>.json"
  And the event "metaData.sidekiq.msg.created_at" is a parsable timestamp in seconds
  And the event "metaData.sidekiq.msg.enqueued_at" is a parsable timestamp in seconds

  Examples:
  | ruby version | sidekiq_version | created_at_present |
  | 1.9.3        | '~> 2'          | false              |
  | 2.0          | '~> 2'          | false              |
  | 2.0          | '~> 3'          | true               |
  | 2.1          | '~> 2'          | false              |
  | 2.1          | '~> 3'          | true               |
  | 2.2          | '~> 2'          | false              |
  | 2.2          | '~> 3'          | true               |
  | 2.2          | '~> 4'          | true               |
  | 2.2          | '~> 5'          | true               |
  | 2.3          | '~> 2'          | false              |
  | 2.3          | '~> 3'          | true               |
  | 2.3          | '~> 4'          | true               |
  | 2.3          | '~> 5'          | true               |
  | 2.4          | '~> 2'          | false              |
  | 2.4          | '~> 3'          | true               |
  | 2.4          | '~> 4'          | true               |
  | 2.4          | '~> 5'          | true               |
  | 2.5          | '~> 2'          | false              |
  | 2.5          | '~> 3'          | true               |
  | 2.5          | '~> 4'          | true               |
  | 2.5          | '~> 5'          | true               |