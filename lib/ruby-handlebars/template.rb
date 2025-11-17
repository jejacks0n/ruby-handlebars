require_relative 'context'

module Handlebars
  class TemplateHandler
    def initialize(hbs, ast)
      @hbs = hbs
      @ast = ast
    end

    def call(args = nil)
      ctx = ContextHandler.new(@hbs, args)

      @ast.eval(ctx)
    end

    def call_with_context(ctx)
      @ast.eval(ctx)
    end
  end
end
