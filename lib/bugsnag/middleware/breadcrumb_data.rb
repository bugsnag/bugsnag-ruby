module Bugsnag::Middleware
    class BreadcrumbData
      def initialize(bugsnag)
        @bugsnag = bugsnag
      end
  
      def call(report)
        if report.configuration.recorder
          report.breadcrumbs = report.configuration.recorder
        end
  
        @bugsnag.call(report)
      end
    end
  end
  