require 'bugsnag'

class CustomError < RuntimeError
  include Bugsnag::MetaData;
end

def exception_with_meta_data
  exception = CustomError.new
  exception.bugsnag_meta_data = {
    :exception => {
      :exception_type => "FATAL",
      :exception_base => "RuntimeError"
    }
  }
  raise exception
end

def exception_with_context
  exception = CustomError.new
  exception.bugsnag_context = "IntegrationTests"
  raise exception
end

def exception_with_hash
  exception = CustomError.new
  exception.bugsnag_grouping_hash = "ABCDE12345"
  raise exception
end

def exception_with_user_id
  exception = CustomError.new
  exception.bugsnag_user_id = "000001"
  raise exception
end