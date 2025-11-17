require_relative 'default_helper'

module Handlebars
  module Helpers
    class WithHelper < DefaultHelper
      def self.registry_name
        'with'
      end

      def self.apply(context, data, block:, else_block:, collapse:, **_opts)
        if data
          # TODO: helpers need a bit of a rework to handle properly
          #       nested cases with top.second being able to create
          #       two ../../ traversal levels. It has to happen above
          #       this helper, or we need to change how this helper gets
          #       its data.
          context.with_nested_temporary_context(data) do
            stripped_result(block.fn(context), collapse[:helper], else_block.nil? ? collapse[:close] : collapse[:else])
          end
        elsif else_block
          stripped_result(else_block.fn(context), collapse[:else], collapse[:close])
        else
          ""
        end
      end

      def self.apply_as(context, data, name, **opts)
        self.apply(context, { name.to_sym => data }, **opts)
      end
    end
  end
end
