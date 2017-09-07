module Bugsnag::Middleware
    class BreadcrumbData
      def initialize(bugsnag)
        @bugsnag = bugsnag
      end
  
      def call(report)
        if report.configuration.recorder
            report.configuration.recorder.get_breadcrumbs do |breadcrumb|
                report.add_breadcrumb breadcrumb
            end
        end
  
        @bugsnag.call(report)
      end
    end
  end
  