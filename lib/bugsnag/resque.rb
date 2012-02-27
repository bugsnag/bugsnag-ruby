# Resque support

# How to use:
#   Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Bugsnag::Resque]
#   Resque::Failure.backend = Resque::Failure::Multiple
#
module Bugsnag
  class Resque < ::Resque::Failure::Base
    def self.configure(&block)
      unless ::Resque::Failure.backend < ::Resque::Failure::Multiple
        original_backend = ::Resque::Failure.backend
        ::Resque::Failure.backend = ::Resque::Failure::Multiple
        ::Resque::Failure.backend.classes ||= []
        ::Resque::Failure.backend.classes << original_backend
      end

      ::Resque::Failure.backend.classes << self
      ::Bugsnag.configure(&block)
    end

    def save
      Bugsnag.auto_notify(exception, bugsnag_job_data)
    end
    
    private
    def bugsnag_job_data
      {
        :user_id => nil, # TODO: How to infer a user id in resque?
        :context => "resque: #{queue}",
        :meta_data => {
          :payload => payload
        }
      }
    end
  end
end