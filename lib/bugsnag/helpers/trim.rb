require 'uri'
require 'set'
require 'json'

module Bugsnag
  module Helpers
    MAX_STRING_LENGTH = 3072
    MAX_PAYLOAD_LENGTH = 256000
    MAX_ARRAY_LENGTH = 40
    RAW_DATA_TYPES = [Numeric, TrueClass, FalseClass]

    class << self
      ##
      # Trim the size of value if the serialized JSON value is longer than is
      # accepted by Bugsnag
      def trim_if_needed(value)
        value = "" if value.nil?
        sanitized_value = Bugsnag::Cleaner.clean_object_encoding(value)
        return sanitized_value unless payload_too_long?(sanitized_value)
        reduced_value = trim_strings_in_value(sanitized_value)
        return reduced_value unless payload_too_long?(reduced_value)
        reduced_value = truncate_arrays_in_value(reduced_value)
        return reduced_value unless payload_too_long?(reduced_value)
        remove_metadata_from_events(reduced_value)
      end

      private

      TRUNCATION_INFO = '[TRUNCATED]'

      ##
      # Check if a value is a raw type which should not be trimmed, truncated
      # or converted to a string
      def json_raw_type?(value)
        RAW_DATA_TYPES.detect { |klass| value.is_a?(klass) } != nil
      end

      # Shorten array until it fits within the payload size limit when serialized
      def truncate_array(array)
        return [] unless array.respond_to?(:slice)
        array.slice(0, MAX_ARRAY_LENGTH).map do |item|
          truncate_arrays_in_value(item)
        end
      end

      # Trim all strings to be less than the maximum allowed string length
      def trim_strings_in_value(value)
        return value if json_raw_type?(value)
        case value
        when Hash
          trim_strings_in_hash(value)
        when Array, Set
          trim_strings_in_array(value)
        else
          trim_as_string(value)
        end
      end

      # Validate that the serialized JSON string value is below maximum payload
      # length
      def payload_too_long?(value)
        if value.is_a?(String)
          value.length >= MAX_PAYLOAD_LENGTH
        else
          ::JSON.dump(value).length >= MAX_PAYLOAD_LENGTH
        end
      end

      def trim_strings_in_hash(hash)
        return {} unless hash.is_a?(Hash)
        hash.each_with_object({}) do |(key, value), reduced_hash|
          if (reduced_value = trim_strings_in_value(value))
            reduced_hash[key] = reduced_value
          end
        end
      end

      # If possible, convert the provided object to a string and trim to the
      # maximum allowed string length
      def trim_as_string(text)
        return "" unless text.respond_to? :to_s
        text = text.to_s
        if text.length > MAX_STRING_LENGTH
          length = MAX_STRING_LENGTH - TRUNCATION_INFO.length
          text = text.slice(0, length) + TRUNCATION_INFO
        end
        text
      end

      def trim_strings_in_array(collection)
        return [] unless collection.respond_to?(:map)
        collection.map { |value| trim_strings_in_value(value) }
      end

      def truncate_arrays_in_value(value)
        case value
        when Hash
          truncate_arrays_in_hash(value)
        when Array, Set
          truncate_array(value)
        else
          value
        end
      end

      # Remove `metaData` from array of `events` within object
      def remove_metadata_from_events(object)
        return {} unless object.is_a?(Hash) && object[:events].respond_to?(:map)
        object[:events].map do |event|
          event.delete(:metaData) if object.is_a?(Hash)
        end
        object
      end

      def truncate_arrays_in_hash(hash)
        return {} unless hash.is_a?(Hash)
        hash.each_with_object({}) do |(key, value), reduced_hash|
          if (reduced_value = truncate_arrays_in_value(value))
            reduced_hash[key] = reduced_value
          end
        end
      end
    end
  end
end
