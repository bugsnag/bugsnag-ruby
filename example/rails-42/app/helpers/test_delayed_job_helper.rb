require "bugsnag"

module TestDelayedJobHelper
  def test_dj(func)
    case func
    when :crash
      self.delay.crash
    when :notify
      self.delay.notify
    end
  end

  def crash
    raise StandardError
  end

  def notify
    Bugsnag.notify(StandardError.new "notify error")
  end

end

