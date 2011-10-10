require 'helper'

class TestBugsnag < Test::Unit::TestCase
  should "get a 200 response from bugsnag.com for basic exceptions" do
    flunk "oh my" if lets.code != 200
  end
  
  private
  def lets
    begin
      go
    rescue Exception => e
      event = Bugsnag::Event.new(e, "12345", {:app_environment => {:releaseStage => "production"}})

      # Bugsnag::Notifier.set_endpoint("http://localhost:8000")
      # Bugsnag::Notifier.notify("145260904aa22d52bf2a82076d157c38", event)

      return Bugsnag::Notifier.notify("d6db01214d22ac808ce6afdfa4c3f148", event)
    end
  end

  def go
    deep
  end

  def deep
    raise RuntimeError.new("Stuff happens")
  end
end