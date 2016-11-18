module Bugsnag::Middleware
  class ClearanceUser
    COMMON_USER_FIELDS = [:email, :name, :first_name, :last_name, :created_at, :id]

    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(notification)
      if notification.request_data[:rack_env] &&
            notification.request_data[:rack_env][:clearance] &&
            notification.request_data[:rack_env][:clearance].signed_in? &&
            notification.request_data[:rack_env][:clearance].current_user

        # Extract useful user information
        user = {}
        user_object = notification.request_data[:rack_env][:clearance].current_user
        if user_object
          # Build the bugsnag user info from the current user record
          COMMON_USER_FIELDS.each do |field|
            user[field] = user_object.send(field) if user_object.respond_to?(field)
          end
        end

        notification.user = user unless user.empty?
      end

      @bugsnag.call(notification)
    end
  end
end
