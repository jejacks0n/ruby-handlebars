require_relative 'default_helper'

module Handlebars
  module Helpers
    class LookupHelper < DefaultHelper
      def self.registry_name
        'lookup'
      end

      def self.apply(context, lookup, key, collapse:, **_opts)
        result = lookup.respond_to?(:[]) ? lookup[key] : nil
        return result unless result.is_a?(String)

        stripped_result(result, collapse[:helper], collapse[:close])
      end
    end
  end
end
