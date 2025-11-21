require "parslet"

require_relative "ruby-handlebars/context"
require_relative "ruby-handlebars/helper"
require_relative "ruby-handlebars/parser"
require_relative "ruby-handlebars/safe_string"
require_relative "ruby-handlebars/template"
require_relative "ruby-handlebars/tree"
require_relative "ruby-handlebars/escapers/html_escaper"
require_relative "ruby-handlebars/helpers/register_default_helpers"

module Handlebars
  MissingPartial = Class.new(StandardError)

  def self.escape_expression(expression)
    Escapers::HTMLEscaper.escape(expression)
  end

  class Handlebars
    attr_reader :escaper

    def initialize()
      @as_helpers = {}
      @helpers = {}
      @partials = {}
      register_default_helpers
      set_escaper
    end

    def compile(template)
      Template.new(self, template_to_ast(template))
    end

    def register_helper(name, as: false, &fn)
      (as ? @as_helpers : @helpers)[name.to_s] = Helper.new(self, fn)
    end

    def register_as_helper(name, &fn)
      @as_helpers[name.to_s] = Helper.new(self, fn)
    end

    def get_helper(name, as: false)
      (as ? @as_helpers : @helpers)[name.to_s]
    end

    def register_partial(name, content)
      @partials[name.to_s] = { content: content, compiled: nil }
    end

    def get_partial(name, raise_on_missing: true)
      partial = @partials[name.to_s]

      if partial.nil?
        raise(::Handlebars::MissingPartial, "Partial \"#{name}\" not registered.") if raise_on_missing
        return nil
      end

      # compile the partial now that we know it's going to be used.
      partial[:compiled] ||= Template.new(self, template_to_ast(partial[:content]))
    end

    def escape_expression(expression)
      @escaper.escape(expression)
    end

    def set_escaper(escaper = nil)
      @escaper = escaper || Escapers::HTMLEscaper
    end

    private

    PARSER = Parser.new
    TRANSFORM = Transform.new

    def template_to_ast(content)
      TRANSFORM.apply(PARSER.parse(content))
    end

    def register_default_helpers
      Helpers.register_default_helpers(self)
    end
  end
end
