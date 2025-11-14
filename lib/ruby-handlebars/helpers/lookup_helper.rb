require_relative 'default_helper'

module Handlebars
  module Helpers
    class LookupHelper < DefaultHelper
      def self.registry_name
        'lookup'
      end

      def self.apply(context, lookup, key, collapse:, **_opts)
        result = lookup[key]
        return result unless result.is_a?(String)

        result.lstrip! if collapse[:helper]&.collapse_after
        result.rstrip! if collapse[:close]&.collapse_before
        result
      end
    end
  end
end
