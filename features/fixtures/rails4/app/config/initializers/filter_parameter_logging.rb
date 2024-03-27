# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:passw]
Rails.application.config.filter_parameters += [:my_specific_filter]
