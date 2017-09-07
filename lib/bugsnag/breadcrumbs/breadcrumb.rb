module Bugsnag
    module Breadcrumbs
        class Breadcrumb

            MAX_SIZE = 4096
            NAME_SIZE_LIMIT = 30
            NAVIGATION_TYPE = "navigation"
            REQUEST_TYPE = "request"
            PROCESS_TYPE = "process"
            LOG_TYPE = "log"
            USER_TYPE = "user"
            STATE_TYPE = "state"
            ERROR_TYPE = "error"
            MANUAL_TYPE = "manual"

            VALID_TYPES = [
                NAVIGATION_TYPE,
                REQUEST_TYPE,
                PROCESS_TYPE,
                LOG_TYPE,
                USER_TYPE,
                STATE_TYPE,
                ERROR_TYPE,
                MANUAL_TYPE
            ]

            attr_accessor :name
            attr_accessor :type
            attr_accessor :timestamp
            attr_accessor :metadata

            def initialize(name, type, metadata = {})
                self.timestamp = Time.now.utc.strftime "%Y-%m-%dT%H:%MZ"

                if !name || name.length === 0
                    raise ArgumentError, "The breadcrumb name must be a non-empty string"
                end

                if name.length > NAME_SIZE_LIMIT
                    raise ArgumentError, "The breadcrumb name must be not more than #{NAME_SIZE_LIMIT} characters in length"
                end

                if !VALID_TYPES.include? type
                    raise ArgumentError, "The breadcrumb type must be one of the set of standard types"
                end

                self.name = name
                self.type = type
                self.metadata = metadata
            end

            def as_object
                {
                    :timestamp => timestamp,
                    :name => name,
                    :type => type
                }
            end
        end
    end
end