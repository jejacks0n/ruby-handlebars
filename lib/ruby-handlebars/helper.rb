module Handlebars
  class Helper
    def initialize(hbs, fn)
      @hbs = hbs
      @fn = fn
    end

    def apply(name, context, arguments = [], block = [], else_block = [], collapse_options = {})
      apply_as(name, context, arguments, [], block, else_block, collapse_options)
    end

    def apply_as(name, context, arguments = [], as_arguments = [], block = [], else_block = [], collapse_options = {})
      arguments = [arguments] unless arguments.is_a? Array
      args = [context]
      hash = {}
      arguments.each do |arg|
        if arg.is_a?(Hash) && arg.has_key?(:named_parameter)
          named = arg[:named_parameter]
          hash[named[:key].to_s] = named[:value].eval(context)
        else
          args << arg.eval(context)
        end
      end

      as_arguments = [as_arguments] unless as_arguments.is_a? Array
      args += as_arguments.map(&:name)

      blocks = split_block(block, else_block)

      accepted_kwargs = @fn.parameters.select { |type, _| [:key, :keyreq].include?(type) }.map(&:last)
      accepts_any_kwargs = @fn.parameters.any? { |type, _| type == :keyrest }

      kwargs = {}
      kwargs[:name] = name if accepts_any_kwargs || accepted_kwargs.include?(:name)
      kwargs[:hash] = hash.sort if accepts_any_kwargs || accepted_kwargs.include?(:hash)
      kwargs[:block] = blocks[0] if accepts_any_kwargs || accepted_kwargs.include?(:block)
      kwargs[:else_block] = blocks[1] if accepts_any_kwargs || accepted_kwargs.include?(:else_block)
      kwargs[:collapse] = collapse_options if accepts_any_kwargs || accepted_kwargs.include?(:collapse)

      @fn.call(*args, **kwargs)
    end

    private

    def split_block(block, else_block)
      if else_block
        [ensure_block(block), ensure_block(else_block)]
      else
        [ensure_block(block)]
      end
    end

    def ensure_block(block)
      new_block = Tree::Block.new([])
      block.each {|item| new_block.add_item(item) } unless block.nil?
      new_block
    end
  end
end
