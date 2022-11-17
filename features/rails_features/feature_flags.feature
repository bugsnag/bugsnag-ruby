Feature: feature flags

@rails5 @rails6 @rails7
Scenario: adding feature flags for an unhandled error
  Given I start the rails service
  When I navigate to the route "/features/unhandled?flags[a]=1&flags[b]&flags[c]=3&flags[d]=4" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "severity" equals "error"
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" equals "oh no"
  And the event contains the following feature flags:
     | featureFlag   | variant |
     | a             | 1       |
     | b             |         |
     | c             | 3       |
     | d             | 4       |
  # ensure each request can have its own set of feature flags
  When I discard the oldest error
  And I navigate to the route "/features/unhandled?flags[x]=9&flags[y]&flags[z]=7" on the rails app
  And I wait to receive an error
  And the event contains the following feature flags:
     | featureFlag   | variant |
     | x             | 9       |
     | y             |         |
     | z             | 7       |

@rails5 @rails6 @rails7
Scenario: adding feature flags for a handled error
  Given I start the rails service
  When I navigate to the route "/features/handled?flags[ab]=12&flags[cd]=34" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is false
  And the event "severity" equals "warning"
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" equals "ahhh"
  And the event contains the following feature flags:
     | featureFlag   | variant |
     | ab            | 12      |
     | cd            | 34      |
  # ensure each request can have its own set of feature flags
  When I discard the oldest error
  And I navigate to the route "/features/unhandled?flags[e]=h&flags[f]=i&flags[g]" on the rails app
  And I wait to receive an error
  And the event contains the following feature flags:
     | featureFlag   | variant |
     | e             | h       |
     | f             | i       |
     | g             |         |

@rails5 @rails6 @rails7
Scenario: clearing all feature flags doesn't affect subsequent requests
  Given I start the rails service
  When I navigate to the route "/features/unhandled?flags[a]=1&flags[b]&flags[c]=3&flags[d]=4&clear_all_flags" on the rails app
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is true
  And the event "severity" equals "error"
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" equals "oh no"
  And the event has no feature flags
  When I discard the oldest error
  And I navigate to the route "/features/unhandled?flags[x]=9&flags[y]&flags[z]=7" on the rails app
  And I wait to receive an error
  And the event contains the following feature flags:
     | featureFlag   | variant |
     | x             | 9       |
     | y             |         |
     | z             | 7       |
