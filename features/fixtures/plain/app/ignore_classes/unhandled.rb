require './app'
require './ignore_classes/ignore_error'

raise IgnoreError.new "Oh no"