Feature: delivery_method configuration option

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I configure the bugsnag endpoint

Scenario Outline: When the delivery_method is set to :synchronous
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby delivery/synchronous.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.config" matches the JSON fixture in "features/fixtures/plain/json/delivery_synchronous.json"

  Examples:
  | ruby version |
  | 1.9.3        |
  | 2.0          |
  | 2.1          |
  | 2.2          |
  | 2.3          |
  | 2.4          |
  | 2.5          |

Scenario Outline: When the delivery_method is set to :thread_queue
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby delivery/threadpool.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.config" matches the JSON fixture in "features/fixtures/plain/json/delivery_threadpool.json"

  Examples:
  | ruby version |
  | 1.9.3        |
  | 2.0          |
  | 2.1          |
  | 2.2          |
  | 2.3          |
  | 2.4          |
  | 2.5          |

Scenario Outline: When the delivery_method is set to :thread_queue in a fork
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby delivery/fork_threadpool.rb"
  And I wait for 1 second
  Then I should receive 2 requests
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.config" matches the JSON fixture in "features/fixtures/plain/json/delivery_fork.json"

  Examples:
  | ruby version |
  | 1.9.3        |
  | 2.0          |
  | 2.1          |
  | 2.2          |
  | 2.3          |
  | 2.4          |
  | 2.5          |