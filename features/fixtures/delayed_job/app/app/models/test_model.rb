class TestModel < ApplicationRecord

  def self.fail_with_args(a)
    raise "uh oh"
  end

  def self.notify
    Bugsnag.notify(RuntimeError.new("Handled exception"))
  end
end
