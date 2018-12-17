require 'mongo'
require 'bugsnag/breadcrumbs/breadcrumbs'

module Bugsnag
  ##
  # Subscribes to, and creates breadcrumbs from, mongo_ruby_driver events
  #
  # @api private
  class MongoBreadcrumbSubscriber

    MONGO_MESSAGE_PREFIX = "Mongo query "
    MONGO_EVENT_PREFIX = "mongo."

    ##
    # Listens to the 'started' event
    #
    # @param event [Object] the mongo_ruby_driver generated event
    def started(event)
      leave_mongo_breadcrumb("started", event)
    end

    ##
    # Listens to the 'succeeded' event
    #
    # @param event [Object] the mongo_ruby_driver generated event
    def succeeded(event)
      leave_mongo_breadcrumb("succeeded", event)
    end

    ##
    # Listens to the 'failed' event
    #
    # @param event [Object] the mongo_ruby_driver generated event
    def failed(event)
      leave_mongo_breadcrumb("failed", event)
    end

    private

    ##
    # Generates breadcrumb data from an event
    #
    # @param event_name [String] the type of event
    # @param event [Object] the mongo_ruby_driver generated event
    def leave_mongo_breadcrumb(event_name, event)
      message = MONGO_MESSAGE_PREFIX + event_name
      meta_data = {
        :event_name => MONGO_EVENT_PREFIX + event_name,
        :command_name => event.command_name,
        :database_name => event.database_name,
        :operation_id => event.operation_id,
        :request_id => event.request_id
      }
      meta_data[:duration] = event.duration if defined?(event.duration)
      meta_data[:message] = event.message if defined?(event.message)

      Bugsnag.leave_breadcrumb(message, meta_data, Bugsnag::Breadcrumbs::PROCESS_BREADCRUMB_TYPE, :auto)
    end
  end
end

##
# Add the subscriber to the global Mongo monitoring object
Mongo::Monitoring::Global.subscribe(Mongo::Monitoring::COMMAND, Bugsnag::MongoBreadcrumbSubscriber.new)
