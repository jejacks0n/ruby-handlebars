require "forwardable"

module Handlebars
  class Context
    extend Forwardable

    PATH_REGEX = /\.\.\/|[^.\/]+/

    def_delegators :@hbs, :escaper, :get_helper, :get_partial, :register_partial

    def initialize(hbs, data)
      @hbs = hbs
      @data = data || {}
    end

    def get(path)
      path = path.to_s
      return true if path == 'true'
      return false if path == 'false'
      return nil if %w[nil null undefined].include?(path)

      if (number = parse_number(path))
        number
      else
        resolve(path)
      end
    end

    def resolve(path)
      items = path.to_s.scan(PATH_REGEX)
      items[-1] = "#{items.shift}#{items[-1]}" if items.first == '@'

      if locals.key?(items.first.to_sym)
        current = locals
      else
        current = @data
      end

      until items.empty? || current.nil?
        current = get_attribute(current, items.shift)
      end

      current
    end

    def escape(string)
      escaper.escape(string)
    end

    def safe(string)
      SafeString.new(string)
    end

    def add_item(key, value)
      locals[key.to_sym] = value
    end

    def add_items(enumerable)
      if enumerable.is_a?(Array)
        enumerable.each_with_index { |v, k| add_item(k.to_s, v) }
      else
        enumerable.map { |k, v| add_item(k, v) }
      end
    end

    def with_nested_context
      saved = get('../')

      add_items(:'../' => locals.empty? ? @data : locals.dup)
      block_result = yield
      locals.merge!(:'../' => saved)

      block_result
    end

    def with_nested_temporary_context(args)
      with_nested_context { with_temporary_context(args) { yield } }
    end

    def with_temporary_context(args = {})
      if args.is_a?(Hash)
        saved = args.keys.collect { |key| [key, get(key.to_s)] }.to_h
      else
        saved = { this: get('this') }
        args = { this: args }
      end

      add_items(args)
      block_result = yield
      locals.merge!(saved)

      block_result
    end

    private

    def locals
      @locals ||= {}
    end

    def parse_number(val)
      result = Float(val)
      (result % 1).zero? ? result.to_i : result
    rescue ArgumentError, TypeError
      false
    end

    def get_attribute(item, attribute)
      sym_attr = attribute.to_sym
      str_attr = attribute.to_s

      if item.respond_to?(:[]) && item.respond_to?(:has_key?)
        return item[sym_attr] if item.has_key?(sym_attr)
        return item[str_attr] if item.has_key?(str_attr)
      end

      item.send(sym_attr) if item.respond_to?(sym_attr)
    end
  end
end
