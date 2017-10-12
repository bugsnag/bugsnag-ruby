require "bugsnag"

module TestDelayedJobHelper
  def test_dj(func)
    case func
    when :crash
      Testers.delay.crash
    when :notify
      Testers.delay.notify
    end
  end

  class Testers
    def self.crash
      raise StandardError
    end

    def self.notify
      Bugsnag.notify(StandardError.new "notify error")
    end
  end
end

