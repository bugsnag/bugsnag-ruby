require 'bugsnag'

class IgnoredError < RuntimeError
end

Bugsnag.configure do |conf|
  conf.ignore_classes << IgnoredError
end