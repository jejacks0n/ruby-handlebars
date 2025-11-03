require_relative 'default_helper'

module Handlebars
  module Helpers
    class WithHelper < DefaultHelper
      def self.registry_name
        'with'
      end

      def self.apply(context, data, block:, else_block:, **_opts)
        if data
          context.with_temporary_context(data) do
            block.fn(context)
          end
        else
          else_block.fn(context)
        end
      end

      def self.apply_as(context, data, name, **opts)
        self.apply(context, { name.to_sym => data }, **opts)
      end
    end
  end
end
