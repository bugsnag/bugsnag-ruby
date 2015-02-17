class PublicInfoSetter
  MESSAGE = "set by middleware"
  def initialize(bugsnag)
    @bugsnag = bugsnag
  end

  def call(notification)
    notification.meta_data[:custom][:info] = MESSAGE
    @bugsnag.call(notification)
  end
end
