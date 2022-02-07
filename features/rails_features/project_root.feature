Feature: Project root configuration

@rails3 @rails4 @rails5 @rails6 @rails7
Scenario: Project_root should default to Rails.root
  Given I start the rails service
  When I navigate to the route "/project_root/default" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" starts with "handled string"
  And the event "metaData.request.url" ends with "/project_root/default"
  And the "file" of the top non-bugsnag stackframe equals "app/controllers/project_root_controller.rb"

@rails3 @rails4 @rails5 @rails6 @rails7
Scenario: Project_root can be set in an initializer
  Given I set environment variable "BUGSNAG_PROJECT_ROOT" to "/foo/bar"
  And I start the rails service
  When I navigate to the route "/project_root/initializer" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" starts with "handled string"
  And the event "metaData.request.url" ends with "/project_root/initializer"
  And the "file" of the top non-bugsnag stackframe equals "/usr/src/app/controllers/project_root_controller.rb"

@rails3 @rails4 @rails5 @rails6 @rails7
Scenario: Project_root can be set after an initializer
  Given I start the rails service
  When I navigate to the route "/project_root/after" on the rails app
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" starts with "handled string"
  And the event "metaData.request.url" ends with "/project_root/after"
  And the "file" of the top non-bugsnag stackframe equals "/usr/src/app/controllers/project_root_controller.rb"
