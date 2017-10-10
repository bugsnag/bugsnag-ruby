class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def index
    raise "YO"
  end

  def crash_after_log
    @test_model = TestModel.new :foo => "Foo"
    @test_model.save
    raise "Crash"
  end
end
