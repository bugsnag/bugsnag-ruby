Feature: Capture user information

@rails3
Scenario Outline: Warden user information is sent
  Given I start the rails service
  When I navigate to the route "/warden/create" on the rails app
  And I navigate to the route "/warden/<route>?email=testtest@test.test" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "user.email" equals "testtest@test.test"
  And the event "user.name" equals "Warden User"
  And the event "user.first_name" equals "Warden"
  And the event "user.last_name" equals "User"

  Examples:
    | route     |
    | handled   |
    | unhandled |

@rails4
Scenario Outline: Devise user information is sent
  Given I start the rails service
  When I navigate to the route "/devise/create" on the rails app
  And I navigate to the route "/devise/<route>" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "user.email" equals "test+test@test.test"
  And the event "user.name" equals "Devise User"
  And the event "user.first_name" equals "Devise"
  And the event "user.last_name" equals "User"

  Examples:
    | route     |
    | handled   |
    | unhandled |

@rails5 @rails6 @rails7 @rails8
Scenario Outline: Clearance user information is sent
  Given I start the rails service
  When I navigate to the route "/clearance/create" on the rails app
  And I navigate to the route "/clearance/<route>" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "user.email" equals "testtest@test.test"
  And the event "user.name" equals "Clearance User"
  And the event "user.first_name" equals "Clearance"
  And the event "user.last_name" equals "User"

  Examples:
    | route     |
    | handled   |
    | unhandled |
