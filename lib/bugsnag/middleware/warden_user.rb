module Bugsnag::Middleware
  class WardenUser
    SCOPE_PATTERN = /^warden\.user\.([^.]+)\.key$/
    COMMON_USER_FIELDS = [:email, :name, :first_name, :last_name, :created_at]

    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(notification)
      if notification.request_data[:rack_env] && notification.request_data[:rack_env]["warden"]
        env = notification.request_data[:rack_env]
        session = env["rack.session"] || {}

        # Find all warden user scopes
        warden_scopes = session.keys.select {|k| k.match(SCOPE_PATTERN)}.map {|k| k.gsub(SCOPE_PATTERN, '\1')}
        unless warden_scopes.empty?
          # Pick the best scope for unique id (the default is "user")
          best_scope = warden_scopes.include?("user") ? "user" : warden_scopes.first

          # Set the user_id
          if best_scope
            scope_key = "warden.user.#{best_scope}.key"
            scope = session[scope_key]
            if scope.is_a? Array
              user_ids = scope.detect {|el| el.is_a? Array}
              if user_ids
                user_id = user_ids.first
                notification.user_id = user_id unless user_id.nil?
              end
            end
          end

          # Extract useful user information
          warden_tab = {}
          warden_scopes.each do |scope|
            user_object = env["warden"].user({:scope => scope, :run_callbacks => false}) rescue nil
            if user_object
              # Build the user info for this scope
              scope_hash = warden_tab["Warden #{scope.capitalize}"] = {}
              COMMON_USER_FIELDS.each do |field|
                scope_hash[field] = user_object.send(field) if user_object.respond_to?(field)
              end
            end
          end

          notification.add_tab(:user, warden_tab) unless warden_tab.empty?
        end
      end

      @bugsnag.call(notification)
    end
  end
end