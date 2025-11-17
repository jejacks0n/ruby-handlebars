require_relative 'default_helper'

module Handlebars
  module Helpers
    class IfHelper < DefaultHelper
      def self.registry_name
        'if'
      end

      def self.apply(context, condition, block:, else_block:, collapse:, **_opts)
        condition = !condition.empty? if condition.respond_to?(:empty?)
        branch(condition, context, block, else_block, collapse)
      end

      def self.branch(condition, context, block, else_block, collapse)
        if condition
          stripped_result(block.fn(context), collapse[:helper], else_block.nil? ? collapse[:close] : collapse[:else])
        elsif else_block
          stripped_result(else_block.fn(context), collapse[:else], collapse[:close])
        else
          ""
        end
      end
    end
  end
end
