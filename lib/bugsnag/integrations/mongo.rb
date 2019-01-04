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
    MONGO_COMMAND_KEY = :bugsnag_mongo_commands

    ##
    # Listens to the 'started' event, storing the command for later usage
    #
    # @param event [Mongo::Event::Base] the mongo_ruby_driver generated event
    def started(event)
      leave_command(event)
    end

    ##
    # Listens to the 'succeeded' event, leaving a breadcrumb
    #
    # @param event [Mongo::Event::Base] the mongo_ruby_driver generated event
    def succeeded(event)
      leave_mongo_breadcrumb("succeeded", event)
    end

    ##
    # Listens to the 'failed' event, leaving a breadcrumb
    #
    # @param event [Mongo::Event::Base] the mongo_ruby_driver generated event
    def failed(event)
      leave_mongo_breadcrumb("failed", event)
    end

    private

    ##
    # Generates breadcrumb data from an event
    #
    # @param event_name [String] the type of event
    # @param event [Mongo::Event::Base] the mongo_ruby_driver generated event
    def leave_mongo_breadcrumb(event_name, event)
      message = MONGO_MESSAGE_PREFIX + event_name
      meta_data = {
        :event_name => MONGO_EVENT_PREFIX + event_name,
        :command_name => event.command_name,
        :database_name => event.database_name,
        :operation_id => event.operation_id,
        :request_id => event.request_id,
        :duration => event.duration
      }
      if command = pop_command(event.request_id)
        collection_key = event.command_name == "getMore" ? "collection" : event.command_name
        meta_data[:collection] = command[collection_key]
        unless command["filter"].nil?
          filters  = command["filter"].map { |key, _v| [key, '?'] }.to_h
          meta_data[:filters] = JSON.dump(filters)
        end
      end
      meta_data[:message] = event.message if defined?(event.message)

      Bugsnag.leave_breadcrumb(message, meta_data, Bugsnag::Breadcrumbs::PROCESS_BREADCRUMB_TYPE, :auto)
    end

    ##
    # Stores the mongo command in the request data by the request_id
    #
    # @param event [Mongo::Event::Base] the mongo_ruby_driver generated event
    def leave_command(event)
      event_commands[event.request_id] = event.command
    end

    ##
    # Removes and retrieves a stored command from the request data
    #
    # @param request_id [String] the id of the mongo_ruby_driver event
    #
    # @return [Hash|nil] the requested command, or nil if not found
    def pop_command(request_id)
      event_commands.delete(request_id)
    end

    ##
    # Provides access to a thread-based mongo event command hash
    #
    # @return [Hash] the hash of mongo event commands
    def event_commands
      Bugsnag.configuration.request_data[MONGO_COMMAND_KEY] ||= {}
    end
  end
end

##
# Add the subscriber to the global Mongo monitoring object
Mongo::Monitoring::Global.subscribe(Mongo::Monitoring::COMMAND, Bugsnag::MongoBreadcrumbSubscriber.new)
