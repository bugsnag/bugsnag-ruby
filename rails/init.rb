# On Rails 2.x GEM_ROOT/rails/init.rb is auto loaded for all gems
# so this is the place to initialize Rails 2.x plugin support
if Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("3.0")
  require "bugsnag/rails"
else
  Bugsnag.warn "Blocked attempt to initialize legacy Rails 2.x extensions"
end
