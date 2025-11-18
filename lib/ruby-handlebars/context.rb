require "forwardable"

module Handlebars
  class Context
    PATH_REGEX = /\.\.\/|[^.\/]+/

    class Data
      extend Forwardable

      def_delegators :@hash, :[]=, :keys, :key?, :empty?, :merge!, :map

      def initialize(hash)
        @hash = hash
      end

      def [](k)
        return {} unless @hash.respond_to?(:has_key?)
        return @hash[k] if @hash.has_key?(k)
        return @hash[k.to_s] if @hash.has_key?(k.to_s)

        return true if k == :true
        return false if k == :false
        return nil if k == :nil || k == :null
        to_number(k.to_s) || nil
      end

      def dup
        self.class.new(@hash.dup) # shallow copy.
      end

      def has_key?(_k)
        true # yeah, we'll respond to anything.
      end

      def respond_to?(val, _ = false)
        %w[[] has_key?].include?(val.to_s) ? true : false
      end

    private

      def to_number(val)
        result = Float(val)
        (result % 1).zero? ? result.to_i : result
      rescue ArgumentError, TypeError
        false
      end
    end

    def initialize(hbs, data)
      @hbs = hbs
      @data = Data.new(data)
    end

    def get(path)
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

    def escaper
      @hbs.escaper
    end

    def get_helper(name)
      @hbs.get_helper(name)
    end

    def get_as_helper(name)
      @hbs.get_as_helper(name)
    end

    def get_partial(name)
      @hbs.get_partial(name)
    end

    def add_item(key, value)
      locals[key.to_sym] = value
    end

    def add_items(hash)
      hash.map { |k, v| add_item(k, v) }
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
      @locals ||= Data.new({})
    end

    def get_attribute(item, attribute)
      sym_attr = attribute.to_sym
      str_attr = attribute.to_s

      if item.respond_to?(:[]) && item.respond_to?(:has_key?)
        if item.has_key?(sym_attr)
          return item[sym_attr]
        elsif item.has_key?(str_attr)
          return item[str_attr]
        end
      end

      if item.respond_to?(sym_attr)
        return item.send(sym_attr)
      end
    end
  end
end
