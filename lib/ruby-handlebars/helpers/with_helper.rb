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
          result = context.with_nested_temporary_context(data) do
            block.fn(context)
          end
          result.lstrip! if collapse[:helper]&.collapse_after
          if else_block
            result.rstrip! if collapse[:else]&.collapse_before
          else
            result.rstrip! if collapse[:close]&.collapse_before
          end
        elsif else_block
          result = else_block.fn(context)
          result.lstrip! if collapse[:else]&.collapse_after
          result.rstrip! if collapse[:close]&.collapse_before
        else
          return ""
        end

        result
      end

      def self.apply_as(context, data, name, **opts)
        self.apply(context, { name.to_sym => data }, **opts)
      end
    end
  end
end
