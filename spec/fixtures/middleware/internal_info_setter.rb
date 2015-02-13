class InternalInfoSetter
  MESSAGE = "set by internal_middleware"
  def initialize(bugsnag)
    @bugsnag = bugsnag
  end

  def call(notification)
    notification.info = MESSAGE
    @bugsnag.call(notification)
  end
end
