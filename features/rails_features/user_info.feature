Feature: Capture user information

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

@rails3
Scenario Outline: Warden user information is sent
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/warden/create" on port "6128<rails_version>"
  And I navigate to the route "/warden/<route>?email=testtest@test.test" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the payload field "events" is an array with 1 element
  And the event "user.email" equals "testtest@test.test"
  And the event "user.name" equals "Warden User"
  And the event "user.first_name" equals "Warden"
  And the event "user.last_name" equals "User"

  Examples:
    | ruby_version | rails_version | route     |
    | 2.0          | 3             | handled   |
    | 2.0          | 3             | unhandled |
    | 2.1          | 3             | handled   |
    | 2.1          | 3             | unhandled |
    | 2.2          | 3             | handled   |
    | 2.2          | 3             | unhandled |
    | 2.3          | 3             | handled   |
    | 2.3          | 3             | unhandled |
    | 2.4          | 3             | handled   |
    | 2.4          | 3             | unhandled |
    | 2.5          | 3             | handled   |
    | 2.5          | 3             | unhandled |

@rails4
Scenario Outline: Devise user information is sent
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/devise/create" on port "6128<rails_version>"
  And I navigate to the route "/devise/<route>" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the payload field "events" is an array with 1 element
  And the event "user.email" equals "test+test@test.test"
  And the event "user.name" equals "Devise User"
  And the event "user.first_name" equals "Devise"
  And the event "user.last_name" equals "User"

  Examples:
    | ruby_version | rails_version | route     |
    | 2.2          | 4             | handled   |
    | 2.2          | 4             | unhandled |
    | 2.3          | 4             | handled   |
    | 2.3          | 4             | unhandled |

@rails5 @rails6
Scenario Outline: Clearance user information is sent
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/clearance/create" on port "6128<rails_version>"
  And I navigate to the route "/clearance/<route>" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the payload field "events" is an array with 1 element
  And the event "user.email" equals "testtest@test.test"
  And the event "user.name" equals "Clearance User"
  And the event "user.first_name" equals "Clearance"
  And the event "user.last_name" equals "User"

  Examples:
    | ruby_version | rails_version | route     |
    | 2.2          | 5             | handled   |
    | 2.2          | 5             | unhandled |
    | 2.3          | 5             | handled   |
    | 2.3          | 5             | unhandled |
    | 2.4          | 5             | handled   |
    | 2.4          | 5             | unhandled |
    | 2.5          | 5             | handled   |
    | 2.5          | 5             | unhandled |
    | 2.5          | 6             | handled   |
    | 2.5          | 6             | unhandled |
    | 2.6          | 5             | handled   |
    | 2.6          | 5             | unhandled |
    | 2.6          | 6             | handled   |
    | 2.6          | 6             | unhandled |