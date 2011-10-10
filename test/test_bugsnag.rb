require 'helper'

class BugsnagTestException < RuntimeError; end

class TestBugsnag < Test::Unit::TestCase
  should "get a 200 response from bugsnag for exceptions" do
    Bugsnag.configure do |config|
      config.api_key = "a799e9c27c3fb3017e4a556fd815317e"
      config.endpoint = "http://localhost:8000/notify"
      config.release_stage = "production"
      config.project_root = File.dirname(__FILE__)
      config.user_id = "static_user_id"
    end
    
    begin
      raise BugsnagTestException.new("Exception test from bugsnag gem")
    rescue Exception => e
      response = Bugsnag.notify(e)
      flunk "oh my" if response.code != 200
    end
  end
end