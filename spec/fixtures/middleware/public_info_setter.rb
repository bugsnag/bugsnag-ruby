class PublicInfoSetter
  MESSAGE = "set by middleware"
  def initialize(bugsnag)
    @bugsnag = bugsnag
  end

  def call(report)
    report.meta_data.merge!({custom: {info: MESSAGE}})
    @bugsnag.call(report)
  end
end
