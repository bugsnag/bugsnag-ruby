Feature: Plain report modify stack frames

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I configure the bugsnag endpoint

Scenario Outline: Stack frames can be removed
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby stack_frame_modification/remove_stack_frame.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the "file" of the top non-bugsnag stackframe equals "/usr/src/app/stack_frame_modification/initiators/<initiator>.rb"
  And the "lineNumber" of stack frame 0 equals <lineNumber>

  Examples:
  | ruby version | initiator               | lineNumber |
  | 1.9.3        | handled_before_notify   | 20         |
  | 1.9.3        | unhandled_before_notify | 21         |
  | 2.0          | handled_before_notify   | 20         |
  | 2.0          | unhandled_before_notify | 21         |
  | 2.1          | handled_before_notify   | 20         |
  | 2.1          | unhandled_before_notify | 21         |
  | 2.2          | handled_before_notify   | 20         |
  | 2.2          | unhandled_before_notify | 21         |
  | 2.3          | handled_before_notify   | 20         |
  | 2.3          | unhandled_before_notify | 21         |
  | 2.4          | handled_before_notify   | 20         |
  | 2.4          | unhandled_before_notify | 21         |
  | 2.5          | handled_before_notify   | 20         |
  | 2.5          | unhandled_before_notify | 21         |

Scenario Outline: Stack frames can be removed
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "CALLBACK_INITIATOR" to "handled_block"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby stack_frame_modification/remove_stack_frame.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the "file" of the top non-bugsnag stackframe equals "/usr/src/app/stack_frame_modification/initiators/handled_block.rb"
  And the "lineNumber" of the top non-bugsnag stackframe equals <lineNumber>

  Examples:
  | ruby version | lineNumber |
  | 1.9.3        | 19         |
  | 2.0          | 19         |
  | 2.1          | 19         |
  | 2.2          | 19         |
  | 2.3          | 19         |
  | 2.4          | 19         |
  | 2.5          | 19         |

Scenario Outline: Stack frames can be marked as in project
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby stack_frame_modification/mark_frames_in_project.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the "file" of stack frame 0 equals "/usr/src/app/stack_frame_modification/initiators/<initiator>.rb"
  And the event "exceptions.0.stacktrace.0.inProject" is null
  And the event "exceptions.0.stacktrace.1.inProject" is true
  And the event "exceptions.0.stacktrace.2.inProject" is true
  And the event "exceptions.0.stacktrace.3.inProject" is true

  Examples:
  | ruby version | initiator               |
  | 1.9.3        | handled_before_notify   |
  | 1.9.3        | unhandled_before_notify |
  | 2.0          | handled_before_notify   |
  | 2.0          | unhandled_before_notify |
  | 2.1          | handled_before_notify   |
  | 2.1          | unhandled_before_notify |
  | 2.2          | handled_before_notify   |
  | 2.2          | unhandled_before_notify |
  | 2.3          | handled_before_notify   |
  | 2.3          | unhandled_before_notify |
  | 2.4          | handled_before_notify   |
  | 2.4          | unhandled_before_notify |
  | 2.5          | handled_before_notify   |
  | 2.5          | unhandled_before_notify |

Scenario Outline: Stack frames can be marked as in project with a handled string
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "CALLBACK_INITIATOR" to "handled_block"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby stack_frame_modification/mark_frames_in_project.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the "file" of the top non-bugsnag stackframe equals "/usr/src/app/stack_frame_modification/initiators/handled_block.rb"
  And the event "exceptions.0.stacktrace.0.inProject" is null
  And the event "exceptions.0.stacktrace.1.inProject" is true
  And the event "exceptions.0.stacktrace.2.inProject" is true
  And the event "exceptions.0.stacktrace.3.inProject" is true

  Examples:
  | ruby version |
  | 1.9.3        |
  | 2.0          |
  | 2.1          |
  | 2.2          |
  | 2.3          |
  | 2.4          |
  | 2.5          |