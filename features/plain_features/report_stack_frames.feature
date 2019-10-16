Feature: Plain report modify stack frames

Scenario Outline: Stack frames can be removed
  Given I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  When I run the service "plain-ruby" with the command "bundle exec ruby stack_frame_modification/remove_stack_frame.rb"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the "file" of the top non-bugsnag stackframe equals "/usr/src/app/stack_frame_modification/initiators/<initiator>.rb"
  And the "lineNumber" of stack frame 0 equals <lineNumber>

  Examples:
  | initiator               | lineNumber |
  | handled_before_notify   | 20         |
  | unhandled_before_notify | 21         |

Scenario: Stack frames can be removed from a notified string
  Given I set environment variable "CALLBACK_INITIATOR" to "handled_block"
  When I run the service "plain-ruby" with the command "bundle exec ruby stack_frame_modification/remove_stack_frame.rb"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the "file" of the top non-bugsnag stackframe equals "/usr/src/app/stack_frame_modification/initiators/handled_block.rb"
  And the "lineNumber" of the top non-bugsnag stackframe equals 19

Scenario Outline: Stack frames can be marked as in project
  Given I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  When I run the service "plain-ruby" with the command "bundle exec ruby stack_frame_modification/mark_frames_in_project.rb"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the "file" of stack frame 0 equals "/usr/src/app/stack_frame_modification/initiators/<initiator>.rb"
  And the event "exceptions.0.stacktrace.0.inProject" is null
  And the event "exceptions.0.stacktrace.1.inProject" is true
  And the event "exceptions.0.stacktrace.2.inProject" is true
  And the event "exceptions.0.stacktrace.3.inProject" is true

  Examples:
  | initiator               |
  | handled_before_notify   |
  | unhandled_before_notify |

Scenario: Stack frames can be marked as in project with a handled string
  Given I set environment variable "CALLBACK_INITIATOR" to "handled_block"
  And I run the service "plain-ruby" with the command "bundle exec ruby stack_frame_modification/mark_frames_in_project.rb"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the "file" of the top non-bugsnag stackframe equals "/usr/src/app/stack_frame_modification/initiators/handled_block.rb"
  And the event "exceptions.0.stacktrace.0.inProject" is null
  And the event "exceptions.0.stacktrace.1.inProject" is true
  And the event "exceptions.0.stacktrace.2.inProject" is true
  And the event "exceptions.0.stacktrace.3.inProject" is true
