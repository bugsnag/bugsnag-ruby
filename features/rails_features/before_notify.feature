Feature: Before notify callbacks

@rails3 @rails4 @rails5 @rails6 @rails7
Scenario: Rails before_notify controller method works on handled errors
  Given I start the rails service
  When I navigate to the route "/before_notify/handled" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" starts with "handled string"
  And the event "unhandled" is false
  And the event "app.type" equals "rails"
  And the event "metaData.request.url" ends with "/before_notify/handled"
  And the event "metaData.before_notify.source" equals "rails_before_handled"
  And the event "metaData.controller.name" equals "BeforeNotifyController"

@rails3 @rails4 @rails5 @rails6 @rails7
Scenario: Rails before_notify controller method works on unhandled errors
  Given I start the rails service
  When I navigate to the route "/before_notify/unhandled" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the exception "errorClass" equals "NameError"
  And the exception "message" starts with "undefined local variable or method `generate_unhandled_error' for #<BeforeNotifyController"
  And the event "unhandled" is true
  And the event "app.type" equals "rails"
  And the event "metaData.request.url" ends with "/before_notify/unhandled"
  And the event "metaData.before_notify.source" equals "rails_before_unhandled"
  And the event "metaData.controller.name" equals "BeforeNotifyController"

@rails3 @rails4 @rails5 @rails6 @rails7
Scenario: Inline block on handled errors is called
  Given I start the rails service
  When I navigate to the route "/before_notify/inline" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" starts with "handled string"
  And the event "unhandled" is false
  And the event "app.type" equals "rails"
  And the event "metaData.request.url" ends with "/before_notify/inline"
  And the event "metaData.before_notify.source" equals "rails_inline"
  And the event "metaData.controller.name" equals "BeforeNotifyController"

