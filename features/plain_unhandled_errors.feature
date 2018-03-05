Feature: Plain unhandled errors

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

Scenario Outline: An unhandled error sends a report
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I build the service "plain-ruby" from the compose file "features/fixtures/plain/docker-compose.yml"
  And I run the command "plain-ruby bundle exec ruby unhandled/<file>.rb" on the service "features/fixtures/plain/docker-compose.yml"
  And I wait for 1 second
  Then I should receive a request
  And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "unhandled" is true
  And the event "severity" is "error"
  And the exception "errorClass" equals "<error>"
  And the "file" of stack frame 0 equals "/usr/src/unhandled/<file>.rb"
  
  Examples:
  | ruby version | file            | error          |
  | 1.9.3        | RuntimeError    | RuntimeError   |
  | 1.9.3        | LoadError       | LoadError      |
  | 1.9.3        | SyntaxError     | SyntaxError    |
  | 1.9.3        | LocalJumpError  | LocalJumpError |
  | 1.9.3        | NameError       | NameError      |
  | 1.9.3        | NoMethodError   | NoMethodError  |
  | 1.9.3        | SystemCallError | Errno::ENOENT  |
  | 1.9.3        | CustomError     | CustomError    |
  | 2.0.0        | RuntimeError    | RuntimeError   |
  | 2.0.0        | LoadError       | LoadError      |
  | 2.0.0        | SyntaxError     | SyntaxError    |
  | 2.0.0        | LocalJumpError  | LocalJumpError |
  | 2.0.0        | NameError       | NameError      |
  | 2.0.0        | NoMethodError   | NoMethodError  |
  | 2.0.0        | SystemCallError | Errno::ENOENT  |
  | 2.0.0        | CustomError     | CustomError    |
  | 2.1.0        | RuntimeError    | RuntimeError   |
  | 2.1.0        | LoadError       | LoadError      |
  | 2.1.0        | SyntaxError     | SyntaxError    |
  | 2.1.0        | LocalJumpError  | LocalJumpError |
  | 2.1.0        | NameError       | NameError      |
  | 2.1.0        | NoMethodError   | NoMethodError  |
  | 2.1.0        | SystemCallError | Errno::ENOENT  |
  | 2.1.0        | CustomError     | CustomError    |
  | 2.2.0        | RuntimeError    | RuntimeError   |
  | 2.2.0        | LoadError       | LoadError      |
  | 2.2.0        | SyntaxError     | SyntaxError    |
  | 2.2.0        | LocalJumpError  | LocalJumpError |
  | 2.2.0        | NameError       | NameError      |
  | 2.2.0        | NoMethodError   | NoMethodError  |
  | 2.2.0        | SystemCallError | Errno::ENOENT  |
  | 2.2.0        | CustomError     | CustomError    |
  | 2.3.0        | RuntimeError    | RuntimeError   |
  | 2.3.0        | LoadError       | LoadError      |
  | 2.3.0        | SyntaxError     | SyntaxError    |
  | 2.3.0        | LocalJumpError  | LocalJumpError |
  | 2.3.0        | NameError       | NameError      |
  | 2.3.0        | NoMethodError   | NoMethodError  |
  | 2.3.0        | SystemCallError | Errno::ENOENT  |
  | 2.3.0        | CustomError     | CustomError    |
  | 2.4.0        | RuntimeError    | RuntimeError   |
  | 2.4.0        | LoadError       | LoadError      |
  | 2.4.0        | SyntaxError     | SyntaxError    |
  | 2.4.0        | LocalJumpError  | LocalJumpError |
  | 2.4.0        | NameError       | NameError      |
  | 2.4.0        | NoMethodError   | NoMethodError  |
  | 2.4.0        | SystemCallError | Errno::ENOENT  |
  | 2.4.0        | CustomError     | CustomError    |
  | 2.5.0        | RuntimeError    | RuntimeError   |
  | 2.5.0        | LoadError       | LoadError      |
  | 2.5.0        | SyntaxError     | SyntaxError    |
  | 2.5.0        | LocalJumpError  | LocalJumpError |
  | 2.5.0        | NameError       | NameError      |
  | 2.5.0        | NoMethodError   | NoMethodError  |
  | 2.5.0        | SystemCallError | Errno::ENOENT  |
  | 2.5.0        | CustomError     | CustomError    |

Scenario Outline: An unhandled error shouldn't send a report
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "ruby_version" to "<ruby version>"
  And I build the service "plain-ruby" from the compose file "features/fixtures/plain/docker-compose.yml"
  And I run the command "plain-ruby bundle exec ruby unhandled/<file>.rb" on the service "features/fixtures/plain/docker-compose.yml"
  And I wait for 1 second
  Then I should receive 0 requests
  
  Examples:
  | ruby version | file        |
  | 1.9.3        | Interrupt    |
  | 1.9.3        | SystemExit   |
  | 2.0.0        | Interrupt    |
  | 2.0.0        | SystemExit   |
  | 2.1.0        | Interrupt    |
  | 2.1.0        | SystemExit   |
  | 2.2.0        | Interrupt    |
  | 2.2.0        | SystemExit   |
  | 2.3.0        | Interrupt    |
  | 2.3.0        | SystemExit   |
  | 2.4.0        | Interrupt    |
  | 2.4.0        | SystemExit   |
  | 2.5.0        | Interrupt    |
  | 2.5.0        | SystemExit   |