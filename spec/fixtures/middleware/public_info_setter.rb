class PublicInfoSetter
  MESSAGE = "set by middleware"
  def initialize(bugsnag)
    @bugsnag = bugsnag
  end

  def call(notification)
    notification.info = MESSAGE
    @bugsnag.call(notification)
  end
end
