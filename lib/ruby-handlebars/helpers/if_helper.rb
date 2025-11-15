require_relative 'default_helper'

module Handlebars
  module Helpers
    class IfHelper < DefaultHelper
      def self.registry_name
        'if'
      end

      def self.apply(context, condition, block:, else_block:, collapse:, **_opts)
        condition = !condition.empty? if condition.respond_to?(:empty?)

        if condition
          result = block.fn(context)
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
    end
  end
end
