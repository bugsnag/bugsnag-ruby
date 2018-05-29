Feature: Plain unhandled errors

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

Scenario Outline: An unhandled error sends a report
  And I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby unhandled/<file>.rb"
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
  | ruby version | file              | error          | lineNumber |
  | 1.9.3        | runtime_error     | RuntimeError   | 6          |
  | 1.9.3        | load_error        | LoadError      | 6          |
  | 1.9.3        | syntax_error      | SyntaxError    | 6          |
  | 1.9.3        | local_jump_error  | LocalJumpError | 7          |
  | 1.9.3        | name_error        | NameError      | 6          |
  | 1.9.3        | no_method_error   | NoMethodError  | 6          |
  | 1.9.3        | system_call_error | Errno::ENOENT  | 6          |
  | 1.9.3        | custom_error      | CustomError    | 9          |
  | 2.0          | runtime_error     | RuntimeError   | 6          |
  | 2.0          | load_error        | LoadError      | 6          |
  | 2.0          | syntax_error      | SyntaxError    | 6          |
  | 2.0          | local_jump_error  | LocalJumpError | 7          |
  | 2.0          | name_error        | NameError      | 6          |
  | 2.0          | no_method_error   | NoMethodError  | 6          |
  | 2.0          | system_call_error | Errno::ENOENT  | 6          |
  | 2.0          | custom_error      | CustomError    | 9          |
  | 2.1          | runtime_error     | RuntimeError   | 6          |
  | 2.1          | load_error        | LoadError      | 6          |
  | 2.1          | syntax_error      | SyntaxError    | 6          |
  | 2.1          | local_jump_error  | LocalJumpError | 7          |
  | 2.1          | name_error        | NameError      | 6          |
  | 2.1          | no_method_error   | NoMethodError  | 6          |
  | 2.1          | system_call_error | Errno::ENOENT  | 6          |
  | 2.1          | custom_error      | CustomError    | 9          |
  | 2.2          | runtime_error     | RuntimeError   | 6          |
  | 2.2          | load_error        | LoadError      | 6          |
  | 2.2          | syntax_error      | SyntaxError    | 6          |
  | 2.2          | local_jump_error  | LocalJumpError | 7          |
  | 2.2          | name_error        | NameError      | 6          |
  | 2.2          | no_method_error   | NoMethodError  | 6          |
  | 2.2          | system_call_error | Errno::ENOENT  | 6          |
  | 2.2          | custom_error      | CustomError    | 9          |
  | 2.3          | runtime_error     | RuntimeError   | 6          |
  | 2.3          | load_error        | LoadError      | 6          |
  | 2.3          | syntax_error      | SyntaxError    | 6          |
  | 2.3          | local_jump_error  | LocalJumpError | 7          |
  | 2.3          | name_error        | NameError      | 6          |
  | 2.3          | no_method_error   | NoMethodError  | 6          |
  | 2.3          | system_call_error | Errno::ENOENT  | 6          |
  | 2.3          | custom_error      | CustomError    | 9          |
  | 2.4          | runtime_error     | RuntimeError   | 6          |
  | 2.4          | load_error        | LoadError      | 6          |
  | 2.4          | syntax_error      | SyntaxError    | 6          |
  | 2.4          | local_jump_error  | LocalJumpError | 7          |
  | 2.4          | name_error        | NameError      | 6          |
  | 2.4          | no_method_error   | NoMethodError  | 6          |
  | 2.4          | system_call_error | Errno::ENOENT  | 6          |
  | 2.4          | custom_error      | CustomError    | 9          |
  | 2.5          | runtime_error     | RuntimeError   | 6          |
  | 2.5          | load_error        | LoadError      | 6          |
  | 2.5          | syntax_error      | SyntaxError    | 6          |
  | 2.5          | local_jump_error  | LocalJumpError | 7          |
  | 2.5          | name_error        | NameError      | 6          |
  | 2.5          | no_method_error   | NoMethodError  | 6          |
  | 2.5          | system_call_error | Errno::ENOENT  | 6          |
  | 2.5          | custom_error      | CustomError    | 9          |

Scenario Outline: An unhandled error doesn't send a report
  And I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby unhandled/<file>.rb"
  And I wait for 1 second
  Then I should receive 0 requests

  Examples:
  | ruby version | file          |
  | 1.9.3        | interrupt     |
  | 1.9.3        | system_exit   |
  | 2.0          | interrupt     |
  | 2.0          | system_exit   |
  | 2.1          | interrupt     |
  | 2.1          | system_exit   |
  | 2.2          | interrupt     |
  | 2.2          | system_exit   |
  | 2.3          | interrupt     |
  | 2.3          | system_exit   |
  | 2.4          | interrupt     |
  | 2.4          | system_exit   |
  | 2.5          | interrupt     |
  | 2.5          | system_exit   |