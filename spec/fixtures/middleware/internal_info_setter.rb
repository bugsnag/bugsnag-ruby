class InternalInfoSetter
  MESSAGE = "set by internal_middleware"
  def initialize(bugsnag)
    @bugsnag = bugsnag
  end

  def call(report)
    report.meta_data.merge!({custom: {info: MESSAGE}})
    @bugsnag.call(report)
  end
end
