class BeforeNotifyController < ActionController::Base
  protect_from_forgery
  before_bugsnag_notify :add_diagnostics_to_bugsnag

  def handled
    Bugsnag.before_notify_callbacks << Proc.new do |report|
      report.add_tab(:before_notify, {
        :source => "rails_before_handled"
      })
    end
    Bugsnag.notify("handled string")
    render json: {}
  end

  def unhandled
    Bugsnag.before_notify_callbacks << Proc.new do |report|
      report.add_tab(:before_notify, {
        :source => "rails_before_unhandled"
      })
    end
    generate_unhandled_error
  end

  def inline
    Bugsnag.notify("handled string") do |report|
      report.add_tab(:before_notify, {
        :source => "rails_inline"
      })
    end
    render json: {}
  end

  private

  def add_diagnostics_to_bugsnag(report)
    report.add_tab(:controller, {
      :name => "BeforeNotifyController"
    })
  end
end
