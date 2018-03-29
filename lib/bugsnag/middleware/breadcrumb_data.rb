module Bugsnag::Middleware
  class BreadcrumbData
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(report)
      report.breadcrumbs = report.configuration.recorder if report.configuration.recorder

      @bugsnag.call(report)
    end
  end
end
