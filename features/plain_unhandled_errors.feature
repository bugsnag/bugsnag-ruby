Feature: Plain unhandled errors

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

Scenario Outline: An unhandled error sends a report
  And I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I build the service "plain-ruby" from the compose file "features/fixtures/plain/docker-compose.yml"
  And I run the command "plain-ruby bundle exec ruby unhandled/<file>.rb" on the service "features/fixtures/plain/docker-compose.yml"
  And I wait for 1 second
  Then I should receive a request
  And the request used the Ruby notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "unhandled" is true
  And the event "severity" is "error"
  And the event "severityReason.type" is "unhandledException"
  And the exception "errorClass" equals "<error>"
  And the "file" of stack frame 0 equals "/usr/src/unhandled/<file>.rb"
  And the "lineNumber" of stack frame 0 equals <lineNumber>

  Examples:
  | ruby version | file            | error          | lineNumber |
  | 1.9.3        | RuntimeError    | RuntimeError   | 6          |
  | 1.9.3        | LoadError       | LoadError      | 6          |
  | 1.9.3        | SyntaxError     | SyntaxError    | 6          |
  | 1.9.3        | LocalJumpError  | LocalJumpError | 7          |
  | 1.9.3        | NameError       | NameError      | 6          |
  | 1.9.3        | NoMethodError   | NoMethodError  | 6          |
  | 1.9.3        | SystemCallError | Errno::ENOENT  | 6          |
  | 1.9.3        | CustomError     | CustomError    | 9          |
  | 2.0          | RuntimeError    | RuntimeError   | 6          |
  | 2.0          | LoadError       | LoadError      | 6          |
  | 2.0          | SyntaxError     | SyntaxError    | 6          |
  | 2.0          | LocalJumpError  | LocalJumpError | 7          |
  | 2.0          | NameError       | NameError      | 6          |
  | 2.0          | NoMethodError   | NoMethodError  | 6          |
  | 2.0          | SystemCallError | Errno::ENOENT  | 6          |
  | 2.0          | CustomError     | CustomError    | 9          |
  | 2.1          | RuntimeError    | RuntimeError   | 6          |
  | 2.1          | LoadError       | LoadError      | 6          |
  | 2.1          | SyntaxError     | SyntaxError    | 6          |
  | 2.1          | LocalJumpError  | LocalJumpError | 7          |
  | 2.1          | NameError       | NameError      | 6          |
  | 2.1          | NoMethodError   | NoMethodError  | 6          |
  | 2.1          | SystemCallError | Errno::ENOENT  | 6          |
  | 2.1          | CustomError     | CustomError    | 9          |
  | 2.2          | RuntimeError    | RuntimeError   | 6          |
  | 2.2          | LoadError       | LoadError      | 6          |
  | 2.2          | SyntaxError     | SyntaxError    | 6          |
  | 2.2          | LocalJumpError  | LocalJumpError | 7          |
  | 2.2          | NameError       | NameError      | 6          |
  | 2.2          | NoMethodError   | NoMethodError  | 6          |
  | 2.2          | SystemCallError | Errno::ENOENT  | 6          |
  | 2.2          | CustomError     | CustomError    | 9          |
  | 2.3          | RuntimeError    | RuntimeError   | 6          |
  | 2.3          | LoadError       | LoadError      | 6          |
  | 2.3          | SyntaxError     | SyntaxError    | 6          |
  | 2.3          | LocalJumpError  | LocalJumpError | 7          |
  | 2.3          | NameError       | NameError      | 6          |
  | 2.3          | NoMethodError   | NoMethodError  | 6          |
  | 2.3          | SystemCallError | Errno::ENOENT  | 6          |
  | 2.3          | CustomError     | CustomError    | 9          |
  | 2.4          | RuntimeError    | RuntimeError   | 6          |
  | 2.4          | LoadError       | LoadError      | 6          |
  | 2.4          | SyntaxError     | SyntaxError    | 6          |
  | 2.4          | LocalJumpError  | LocalJumpError | 7          |
  | 2.4          | NameError       | NameError      | 6          |
  | 2.4          | NoMethodError   | NoMethodError  | 6          |
  | 2.4          | SystemCallError | Errno::ENOENT  | 6          |
  | 2.4          | CustomError     | CustomError    | 9          |
  | 2.5          | RuntimeError    | RuntimeError   | 6          |
  | 2.5          | LoadError       | LoadError      | 6          |
  | 2.5          | SyntaxError     | SyntaxError    | 6          |
  | 2.5          | LocalJumpError  | LocalJumpError | 7          |
  | 2.5          | NameError       | NameError      | 6          |
  | 2.5          | NoMethodError   | NoMethodError  | 6          |
  | 2.5          | SystemCallError | Errno::ENOENT  | 6          |
  | 2.5          | CustomError     | CustomError    | 9          |

Scenario Outline: An unhandled error doesn't send a report
  And I set environment variable "ruby_version" to "<ruby version>"
  And I build the service "plain-ruby" from the compose file "features/fixtures/plain/docker-compose.yml"
  And I run the command "plain-ruby bundle exec ruby unhandled/<file>.rb" on the service "features/fixtures/plain/docker-compose.yml"
  And I wait for 1 second
  Then I should receive 0 requests

  Examples:
  | ruby version | file         |
  | 1.9.3        | Interrupt    |
  | 1.9.3        | SystemExit   |
  | 2.0          | Interrupt    |
  | 2.0          | SystemExit   |
  | 2.1          | Interrupt    |
  | 2.1          | SystemExit   |
  | 2.2          | Interrupt    |
  | 2.2          | SystemExit   |
  | 2.3          | Interrupt    |
  | 2.3          | SystemExit   |
  | 2.4          | Interrupt    |
  | 2.4          | SystemExit   |
  | 2.5          | Interrupt    |
  | 2.5          | SystemExit   |