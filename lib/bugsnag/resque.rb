# Resque support

# How to use:
#   Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Bugsnag::Resque]
#   Resque::Failure.backend = Resque::Failure::Multiple
#
module Bugsnag
  class Resque < Resque::Failure::Base
    def self.configure
      Resque::Failure.backend = self
      ::Bugsnag.configure(&block)
    end

    def save
      Bugsnag.auto_notify(exception, bugsnag_job_data)
    end
    
    private
    def bugsnag_job_data
      {
        :user_id => nil, # TODO: How to infer a user id in resque?
        :context => "#{queue} (resque)",
        :meta_data => {
          :payload => payload
        }
      }
    end
  end
end