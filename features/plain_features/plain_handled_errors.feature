Feature: Plain handled errors

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

Scenario Outline: A handled error sends a report
  And I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I build the service "plain-ruby" from the compose file "features/fixtures/docker-compose.yml"
  And I run the command "plain-ruby bundle exec ruby handled/<file>.rb" on the service "features/fixtures/docker-compose.yml"
  And I wait for 1 second
  Then I should receive a request
  And the request used the Ruby notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "unhandled" is false
  And the event "severity" is "warning"
  And the event "severityReason.type" is "handledException"
  And the exception "errorClass" equals "RuntimeError"
  And the "file" of stack frame 0 equals "/usr/src/handled/<file>.rb"
  And the "lineNumber" of stack frame 0 equals <lineNumber>

  Examples:
  | ruby version | file                | lineNumber |
  | 1.9.3        | notify_exception    | 6          |
  | 1.9.3        | notify_string       | 8          |
  | 2.0          | notify_exception    | 6          |
  | 2.0          | notify_string       | 8          |
  | 2.1          | notify_exception    | 6          |
  | 2.1          | notify_string       | 8          |
  | 2.2          | notify_exception    | 6          |
  | 2.2          | notify_string       | 8          |
  | 2.3          | notify_exception    | 6          |
  | 2.3          | notify_string       | 8          |
  | 2.4          | notify_exception    | 6          |
  | 2.4          | notify_string       | 8          |
  | 2.5          | notify_exception    | 6          |
  | 2.5          | notify_string       | 8          |

Scenario Outline: A handled error doesn't send a report when the :skip_bugsnag flag is set
  And I set environment variable "ruby_version" to "<ruby version>"
  And I build the service "plain-ruby" from the compose file "features/fixtures/docker-compose.yml"
  And I run the command "plain-ruby bundle exec ruby unhandled/ignore_exception.rb" on the service "features/fixtures/docker-compose.yml"
  And I wait for 1 second
  Then I should receive 0 requests

  Examples:
  | ruby version |
  | 1.9.3        |
  | 2.0          |
  | 2.1          |
  | 2.2          |
  | 2.3          |
  | 2.4          |
  | 2.5          |

Scenario Outline: A handled error can attach metadata in a block
  And I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I build the service "plain-ruby" from the compose file "features/fixtures/docker-compose.yml"
  And I run the command "plain-ruby bundle exec ruby handled/block_metadata.rb" on the service "features/fixtures/docker-compose.yml"
  And I wait for 1 second
  Then I should receive a request
  And the request used the Ruby notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "unhandled" is false
  And the event "severity" is "warning"
  And the event "severityReason.type" is "handledException"
  And the exception "errorClass" equals "RuntimeError"
  And the "file" of stack frame 0 equals "/usr/src/handled/block_metadata.rb"
  And the "lineNumber" of stack frame 0 equals 6
  And the event "metaData.account.id" is "1234abcd"
  And the event "metaData.account.name" is "Acme Co"
  And the event "metaData.account.support" is true

  Examples:
  | ruby version |
  | 1.9.3        |
  | 2.0          |
  | 2.1          |
  | 2.2          |
  | 2.3          |
  | 2.4          |
  | 2.5          |