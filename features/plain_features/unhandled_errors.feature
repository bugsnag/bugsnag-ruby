Feature: Plain unhandled errors

Scenario Outline: An unhandled error sends a report
  Given I run the service "plain-ruby" with the command "<command> unhandled/<file>.rb"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledException"
  And the event "device.time" is a timestamp
  And the exception "errorClass" equals "<error>"
  And the "file" of stack frame 0 equals "/usr/src/app/unhandled/<file>.rb"
  And the "lineNumber" of stack frame 0 equals <lineNumber>

  Examples:
  | file              | error          | lineNumber | command          |
  | runtime_error     | RuntimeError   | 6          | bundle exec      |
  | load_error        | LoadError      | 6          | bundle exec      |
  | syntax_error      | SyntaxError    | 6          | bundle exec      |
  | local_jump_error  | LocalJumpError | 7          | bundle exec      |
  | name_error        | NameError      | 6          | bundle exec      |
  | no_method_error   | NoMethodError  | 6          | bundle exec      |
  | system_call_error | Errno::ENOENT  | 6          | bundle exec      |
  | custom_error      | CustomError    | 9          | bundle exec      |
  | runtime_error     | RuntimeError   | 6          | bundle exec ruby |
  | load_error        | LoadError      | 6          | bundle exec ruby |
  | syntax_error      | SyntaxError    | 6          | bundle exec ruby |
  | local_jump_error  | LocalJumpError | 7          | bundle exec ruby |
  | name_error        | NameError      | 6          | bundle exec ruby |
  | no_method_error   | NoMethodError  | 6          | bundle exec ruby |
  | system_call_error | Errno::ENOENT  | 6          | bundle exec ruby |
  | custom_error      | CustomError    | 9          | bundle exec ruby |

Scenario Outline: An unhandled error doesn't send a report
  When I run the service "plain-ruby" with the command "<command> unhandled/<file>.rb"
  Then I should receive no requests

  Examples:
  | file                 | command          |
  | interrupt            | bundle exec      |
  | system_exit          | bundle exec      |
  | exit_after_exception | bundle exec      |
  | interrupt            | bundle exec ruby |
  | system_exit          | bundle exec ruby |
  | exit_after_exception | bundle exec ruby |
