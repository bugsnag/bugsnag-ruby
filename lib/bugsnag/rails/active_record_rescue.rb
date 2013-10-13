module Bugsnag::Rails
  module ActiveRecordRescue
    def run_callbacks(kind, *args, &block)
      if %w(commit rollback).include?(kind.to_s)
        begin
          super
        rescue StandardError => exception
          # This exception will NOT be escalated, so notify it here.
          Bugsnag.auto_notify(exception)
          raise
        end
      else
        # Let the post process handle the exception
        super
      end
    end
  end
end
