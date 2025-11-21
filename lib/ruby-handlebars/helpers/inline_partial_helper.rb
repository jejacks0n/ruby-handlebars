require_relative 'default_helper'

module Handlebars
  module Helpers
    class InlinePartialHelper < DefaultHelper
      def self.registry_name
        '*inline'
      end

      def self.apply(context, name, block:, **_opts)
        context.register_partial(name, block.fn(context))
        nil
      end
    end
  end
end
