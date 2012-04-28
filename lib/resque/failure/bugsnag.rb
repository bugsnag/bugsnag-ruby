# Resque support

# How to use:
#   Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Resque::Failure::Bugsnag]
#   Resque::Failure.backend = Resque::Failure::Multiple
#

begin
  require "bugsnag"
rescue LoadError
  raise "Can't find 'bugsnag' gem. Please add it to your Gemfile or install it."
end

require "resque/failure/base"

module Resque
  module Failure
    class Bugsnag < Base
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
        ::Bugsnag.auto_notify(exception, bugsnag_job_data)
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
end