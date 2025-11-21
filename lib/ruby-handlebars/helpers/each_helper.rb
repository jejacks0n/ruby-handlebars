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

      def self.apply_as(context, items, name, hash:, block:, else_block:, collapse:, **_opts)
        if items.nil? || items.empty?
          result = else_block&.fn(context)
          result&.lstrip! if collapse[:else]&.collapse_after
          result&.rstrip! if collapse[:close]&.collapse_before
          return result
        end

        context.with_nested_context do
          case items
          when Array
            items.each_with_index.map do |item, index|
              add_and_execute(block, context, items, item, index, else_block, collapse, name => item, :@key => index.to_s)
            end.join('')
          when Hash
            items.each_with_index.map do |(key, value), index|
              add_and_execute(block, context, items, value, index, else_block, collapse, name => value, :@key => key.to_s)
            end.join('')
          else
            raise ::Handlebars::UnknownEachType, "unknown type provided to each helper, please provide an array or hash"
          end
        end
      end

      def self.add_and_execute(block, context, items, item, index, else_block, collapse, **extra)
        locals = {
          :@index => index,
          :@first => index == 0,
          :@last => index == items.length - 1
        }

        context.with_temporary_context(locals.merge(extra.to_h)) do
          context.add_items(item) if item.respond_to?(:map)
          stripped_result(block.fn(context), collapse[:helper], else_block.nil? ? collapse[:close] : collapse[:else])
        end
      end
    end
  end
end
