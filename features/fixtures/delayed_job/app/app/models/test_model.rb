class TestModel < ApplicationRecord

  def self.fail_with_args(a)
    raise "uh oh"
  end

  def self.notify_with_args(a)
    Bugsnag.notify(RuntimeError.new("Handled exception"))
  end
end
