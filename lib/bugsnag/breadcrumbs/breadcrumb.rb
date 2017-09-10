module Bugsnag
    module Breadcrumbs

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

        class Breadcrumb

            attr_accessor :name
            attr_accessor :type
            attr_accessor :timestamp
            attr_accessor :metadata

            def initialize(name, type=nil, metadata = {})
                self.timestamp = Time.now.utc.strftime "%Y-%m-%dT%H:%MZ"

                name = name.to_s.slice(0, Bugsnag::Breadcrumbs::NAME_SIZE_LIMIT) 
                type = Breadcrumbs::MANUAL_TYPE unless Breadcrumbs::VALID_TYPES.include? type

                self.name = name
                self.type = type
                self.metadata = metadata
            end

            def as_json
                hash = {
                    :timestamp => timestamp,
                    :name => name,
                    :type => type,
                }
                hash[:metaData] = metadata unless JSON::dump(metadata).length > Bugsnag::Breadcrumbs::MAX_SIZE
                hash
            end
        end
    end
end