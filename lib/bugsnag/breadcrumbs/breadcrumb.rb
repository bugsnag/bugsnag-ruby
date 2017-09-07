module Bugsnag
    module Breadcrumbs

        class << self
            def max_size
                @max_size || = 4096
            end

            def name_size_limit
                @name_size_limit || = 30
            end

            def navigation_type
                @navigation || = "navigation"
            end

            def request_type
                @request || = "request"
            end

            def process_type
                @request || = "process"
            end

            def log_type
                @log || = "log"
            end

            def user_type
                @user || = "user"
            end

            def state_type
                @state || = "state"
            end

            def error_type
                @error || = "error"
            end

            def manual_type
                @manual || = "manual"
            end


            def valid_types
                @types || = [
                    Breadcrumbs::navigation_type,
                    Breadcrumbs::request_type,
                    Breadcrumbs::process_type,
                    Breadcrumbs::log_type,
                    Breadcrumbs::user_type,
                    Breadcrumbs::state_type,
                    Breadcrumbs::error_type,
                    Breadcrumbs::manual_Type
                ]
            end
        end

        class Breadcrumb

            attr_accessor :name
            attr_accessor :type
            attr_accessor :timestamp
            attr_accessor :metadata

            def initialize(name, type, metadata = {})
                timestamp = Time.now.utc.strftime "%Y-%m-%dT%H:%MZ"

                if !name || name.length === 0
                    raise ArgumentError "The breadcrumb name must be a non-empty string"
                end

                if name.length > Breadcrumbs::name_size_limit
                    raise ArgumentError "The breadcrumb name must be not more than #{Breadcrumbs::name_size_limit} characters in length"
                end

                if !valid_types.include? type
                    raise ArgumentError "The breadcrumb type must be one of the set of standard types"
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