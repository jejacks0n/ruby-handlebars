require_relative 'default_helper'

module Handlebars
  UnknownEachType = Class.new(StandardError)
  module Helpers
    class EachHelper < DefaultHelper
      def self.registry_name
        'each'
      end

      def self.apply(context, items, **opts)
        self.apply_as(context, items, :this, **opts)
      end

      def self.apply_as(context, items, name, hash:, block:, else_block:)
        return else_block&.fn(context) if (items.nil? || items.empty?)

        context.with_nested_context do
          case items
          when Array
            items.each_with_index.map do |item, index|
              add_and_execute(block, context, items, item, index, name => item)
            end.join('')
          when Hash
            items.each_with_index.map do |(key, value), index|
              add_and_execute(block, context, items, value, index, name => value, :@key => key.to_s)
            end.join('')
          else
            raise ::Handlebars::UnknownEachType, "unknown type provided to each helper, please provide an array or hash"
          end
        end
      end

      def self.add_and_execute(block, context, items, item, index, **extra)
        locals = {
          :@index => index,
          :@first => index == 0,
          :@last => index == items.length - 1
        }

        context.with_temporary_context(locals.merge(extra.to_h)) do
          context.add_items(item) if item.respond_to?(:map)
          block.fn(context)
        end
      end
    end
  end
end
