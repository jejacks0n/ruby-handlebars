require_relative 'tree'

module Handlebars
  class Helper
    def initialize(hbs, fn)
      @hbs = hbs
      @fn = fn
    end

    def apply(context, arguments = [], block = [], else_block = [])
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
      blocks = split_block(block, else_block)

      @fn.call(*args, hash: hash, block: blocks[0], else_block: blocks[1])
    end

    def apply_as(context, arguments = [], as_arguments = [], block = [], else_block = [])
      arguments = [arguments] unless arguments.is_a? Array
      as_arguments = [as_arguments] unless as_arguments.is_a? Array
      args = [context] + arguments.map {|arg| arg.eval(context)} + as_arguments.map(&:name) + split_block(block, else_block)

      @fn.call(*args)
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
