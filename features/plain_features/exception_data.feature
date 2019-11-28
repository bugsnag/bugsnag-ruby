Feature: Plain exception data

Scenario Outline: An error has built in meta-data
  When I run the service "plain-ruby" with the command "bundle exec ruby exception_data/<state>_meta_data.rb"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the exception "errorClass" equals "CustomError"
  And the event "metaData.exception.exception_type" equals "FATAL"
  And the event "metaData.exception.exception_base" equals "RuntimeError"

  Examples:
  | state     |
  | unhandled |
  | handled   |

Scenario Outline: An error has built in context
  When I run the service "plain-ruby" with the command "bundle exec ruby exception_data/<state>_context.rb"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the exception "errorClass" equals "CustomError"
  And the event "context" equals "IntegrationTests"

  Examples:
  | state     |
  | unhandled |
  | handled   |

Scenario Outline: An error has built in grouping hash
  When I run the service "plain-ruby" with the command "bundle exec ruby exception_data/<state>_hash.rb"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the exception "errorClass" equals "CustomError"
  And the event "groupingHash" equals "ABCDE12345"

  Examples:
  | state     |
  | unhandled |
  | handled   |

Scenario Outline: An error has built in user id
  When I run the service "plain-ruby" with the command "bundle exec ruby exception_data/<state>_user_id.rb"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the exception "errorClass" equals "CustomError"
  And the event "user.id" equals "000001"

  Examples:
  | state     |
  | unhandled |
  | handled   |
