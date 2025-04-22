class ActiveJobController < ActionController::Base
  protect_from_forgery

  def handled
    NotifyJob.perform_later(1, "hello", { a: "a", b: "b" }, keyword: true)

    render json: {}
  end

  def unhandled
    UnhandledJob.perform_later(123, { abc: "xyz" }, "abcxyz")

    render json: {}
  end
end
