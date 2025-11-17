require_relative 'default_helper'

module Handlebars
  module Helpers
    class UnlessHelper < IfHelper
      def self.registry_name
        'unless'
      end

      def self.apply(context, condition, block:, else_block:, collapse:, **_opts)
        condition = !condition.empty? if condition.respond_to?(:empty?)
        branch(!condition, context, block, else_block, collapse)
      end
    end
  end
end
