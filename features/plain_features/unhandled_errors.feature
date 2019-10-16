Feature: Plain unhandled errors

Scenario Outline: An unhandled error sends a report
  Given I run the service "plain-ruby" with the command "bundle exec ruby unhandled/<file>.rb"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event "unhandled" is true
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledException"
  And the exception "errorClass" equals "<error>"
  And the "file" of stack frame 0 equals "/usr/src/app/unhandled/<file>.rb"
  And the "lineNumber" of stack frame 0 equals <lineNumber>

  Examples:
  | file              | error          | lineNumber |
  | runtime_error     | RuntimeError   | 6          |
  | load_error        | LoadError      | 6          |
  | syntax_error      | SyntaxError    | 6          |
  | local_jump_error  | LocalJumpError | 7          |
  | name_error        | NameError      | 6          |
  | no_method_error   | NoMethodError  | 6          |
  | system_call_error | Errno::ENOENT  | 6          |
  | custom_error      | CustomError    | 9          |

Scenario Outline: An unhandled error doesn't send a report
  When I run the service "plain-ruby" with the command "bundle exec ruby unhandled/<file>.rb"
  And I wait for 1 second
  Then I should receive no requests

  Examples:
  | file          |
  | interrupt     |
  | system_exit   |