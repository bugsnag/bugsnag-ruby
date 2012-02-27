require 'helper'
require 'logger'

class BugsnagTestException < RuntimeError; end

class TestBugsnag < Test::Unit::TestCase
  should "send a normal exception" do
    Bugsnag.configure do |config|
      config.api_key = "2dd3f9aaef927b88be4e3c713b663354"
      config.release_stage = "production"
      config.project_root = File.dirname(__FILE__)
      config.logger = Logger.new(STDOUT)
    end
    
    begin
      raise BugsnagTestException.new("Exception test from bugsnag gem")
    rescue Exception => e
      response = Bugsnag.notify(e)
      flunk "oh my" if response.code != 200
    end
  end
end