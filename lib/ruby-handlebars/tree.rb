module Handlebars
  module Tree
    class TreeItem < Struct
      def eval(context)
        _eval(context)
      end
    end

    class TemplateContent < TreeItem.new(:content)
      def _eval(context)
        return content
      end
    end

    class Replacement < TreeItem.new(:item, :collapse_before, :collapse_after)
      def _eval(context)
        if context.get_helper(item.to_s).nil?
          context.get(item.to_s)
        else
          context.get_helper(item.to_s).apply(context)
        end
      end
    end

    class EscapedReplacement < Replacement
      def _eval(context)
        context.escaper.escape(super(context).to_s)
      end
    end

    class String < TreeItem.new(:content)
      def _eval(context)
        return content
      end
    end

    class Parameter < TreeItem.new(:name)
      def _eval(context)
        if name.is_a?(Parslet::Slice)
          context.get(name.to_s)
        else
          name._eval(context)
        end
      end
    end

    class Helper < TreeItem.new(:name, :parameters, :block, :else_block, :collapse_before, :collapse_after)
      def _eval(context)
        helper = context.get_helper(name.to_s)
        if helper.nil?
          context.get_helper('helperMissing').apply(context, String.new(name.to_s))
        else
          helper.apply(context, parameters, block, else_block)
        end
      end
    end

    class AsHelper < TreeItem.new(:name, :parameters, :as_parameters, :block, :else_block, :collapse_before, :collapse_after)
      def _eval(context)
        helper = context.get_as_helper(name.to_s)
        if helper.nil?
          context.get_helper('helperMissing').apply(context, String.new(name.to_s))
        else
          helper.apply_as(context, parameters, as_parameters, block, else_block)
        end
      end
    end

    class EscapedHelper < Helper
      def _eval(context)
        context.escaper.escape(super(context).to_s)
      end
    end

    class Partial < TreeItem.new(:partial_name, :collapse_before, :collapse_after)
      def _eval(context)
        context.get_partial(partial_name.to_s).call_with_context(context)
      end
    end

    class PartialWithArgs < TreeItem.new(:partial_name, :arguments, :collapse_before, :collapse_after)
      def _eval(context)
        [arguments].flatten.map(&:values).map do |vals|
          context.add_item vals.first.to_s, vals.last._eval(context)
        end
        context.get_partial(partial_name.to_s).call_with_context(context)
      end
    end

    class Comment < TreeItem.new(:comment, :collapse_before, :collapse_after)
      def _eval(context)
        ""
      end
    end

    class Block < TreeItem.new(:items)
      def _eval(context)
        items.each_with_index.map do |item, i|
          value = item._eval(context).to_s

          if i > 0 && items[i - 1].respond_to?(:collapse_after) && items[i - 1].collapse_after
            value.lstrip!
          end

          if i < items.length - 1 && items[i + 1].respond_to?(:collapse_before) && items[i + 1].collapse_before
            value.rstrip!
          end

          value
        end.join
      end

      alias :fn :_eval

      def add_item(i)
        items << i
      end
    end
  end

  class Transform < Parslet::Transform
    COLLAPSABLE = {collapse_before: simple(:collapse_before), collapse_after: simple(:collapse_after)}

    rule(
      template_content: simple(:content)
    ) { Tree::TemplateContent.new(content) }

    rule(COLLAPSABLE.merge(
      replaced_unsafe_item: simple(:item)
    )) { Tree::EscapedReplacement.new(item, collapse_before, collapse_after) }

    rule(COLLAPSABLE.merge(
      replaced_safe_item: simple(:item)
    )) { Tree::Replacement.new(item, collapse_before, collapse_after) }

    rule(
      str_content: simple(:content)
    ) { Tree::String.new(content) }

    rule(
      parameter_name: simple(:name)
    ) { Tree::Parameter.new(name) }

    rule(
      comment: simple(:content)
    ) { Tree::Comment.new(content) }

    rule(COLLAPSABLE.merge(
      unsafe_helper_name: simple(:name),
      parameters: subtree(:parameters)
    )) { Tree::EscapedHelper.new(name, parameters, collapse_before, collapse_after) }

    rule(
      unsafe_helper_name: simple(:name),
      parameters: subtree(:parameters)
    ) { Tree::EscapedHelper.new(name, parameters) }

    rule(COLLAPSABLE.merge(
      safe_helper_name: simple(:name),
      parameters: subtree(:parameters)
    )) { Tree::Helper.new(name, parameters, collapse_before, collapse_after) }

    rule(
      safe_helper_name: simple(:name),
      parameters: subtree(:parameters)
    ) { Tree::Helper.new(name, parameters) }

    rule(COLLAPSABLE.merge(
      helper_name: simple(:name),
      block_items: subtree(:block_items),
    )) do
      Tree::Helper.new(name, [], block_items, collapse_before, collapse_after)
    end

    rule(COLLAPSABLE.merge(
      helper_name: simple(:name),
      block_items: subtree(:block_items),
      else_block_items: subtree(:else_block_items)
    )) do
      Tree::Helper.new(name, [], block_items, else_block_items, collapse_before, collapse_after)
    end

    rule(COLLAPSABLE.merge(
      helper_name: simple(:name),
      parameters: subtree(:parameters),
      block_items: subtree(:block_items),
    )) do
      Tree::Helper.new(name, parameters, block_items, collapse_before, collapse_after)
    end

    rule(COLLAPSABLE.merge(
      helper_name: simple(:name),
      parameters: subtree(:parameters),
      block_items: subtree(:block_items),
      else_block_items: subtree(:else_block_items)
    )) do
      Tree::Helper.new(name, parameters, block_items, else_block_items, collapse_before, collapse_after)
    end

    rule(COLLAPSABLE.merge(
      helper_name: simple(:name),
      parameters: subtree(:parameters),
      as_parameters: subtree(:as_parameters),
      block_items: subtree(:block_items),
    )) { Tree::AsHelper.new(name, parameters, as_parameters, block_items, collapse_before, collapse_after) }

    rule(COLLAPSABLE.merge(
      helper_name: simple(:name),
      parameters: subtree(:parameters),
      as_parameters: subtree(:as_parameters),
      block_items: subtree(:block_items),
      else_block_items: subtree(:else_block_items)
    )) { Tree::AsHelper.new(name, parameters, as_parameters, block_items, else_block_items, collapse_before, collapse_after) }

    rule(COLLAPSABLE.merge(
      partial_name: simple(:partial_name),
      arguments: subtree(:arguments)
    )) { Tree::PartialWithArgs.new(partial_name, arguments, collapse_before, collapse_after) }

    rule(COLLAPSABLE.merge(
      partial_name: simple(:partial_name)
    )) { Tree::Partial.new(partial_name, collapse_before, collapse_after) }

    rule(
      block_items: subtree(:block_items)
    ) { Tree::Block.new(block_items) }

    rule(
      else_block_items: subtree(:else_block_items)
    ) { Tree::Block.new(block_items) }
  end
end
