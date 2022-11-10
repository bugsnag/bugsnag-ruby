Feature: Plain add tab to metadata

Scenario Outline: Metadata can be added to a report using add_tab
  Given I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  When I run the service "plain-ruby" with the command "bundle exec ruby report_modification/add_tab.rb"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "metaData.additional_metadata.foo" equals "foo"
  And the event "metaData.additional_metadata.bar.0" equals "b"
  And the event "metaData.additional_metadata.bar.1" equals "a"
  And the event "metaData.additional_metadata.bar.2" equals "r"

  Examples:
  | initiator               |
  | handled_before_notify   |
  | handled_block           |
  | unhandled_before_notify |
  | handled_on_error        |
  | unhandled_on_error      |

Scenario Outline: Metadata can be added to an existing tab using add_tab
  Given I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  When I run the service "plain-ruby" with the command "bundle exec ruby report_modification/add_tab_existing.rb"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "metaData.additional_metadata.foo" equals "foo"
  And the event "metaData.additional_metadata.bar.0" equals "b"
  And the event "metaData.additional_metadata.bar.1" equals "a"
  And the event "metaData.additional_metadata.bar.2" equals "r"
  And the event "metaData.additional_metadata.foobar.first" equals "foo"
  And the event "metaData.additional_metadata.foobar.then" equals "bar"

  Examples:
  | initiator               |
  | handled_before_notify   |
  | handled_block           |
  | unhandled_before_notify |
  | handled_on_error        |
  | unhandled_on_error      |

Scenario Outline: Metadata can be overwritten using add_tab
  Given I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  When I run the service "plain-ruby" with the command "bundle exec ruby report_modification/add_tab_override.rb"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "metaData.additional_metadata.foo" equals "foo"
  And the event "metaData.additional_metadata.bar" equals "bar"

  Examples:
  | initiator               |
  | handled_before_notify   |
  | handled_block           |
  | unhandled_before_notify |
  | handled_on_error        |
  | unhandled_on_error      |
