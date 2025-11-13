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

    class CollapseOptions < TreeItem.new(:collapse_before, :collapse_after)
      def _eval(context)
      end
    end

    class Helper < TreeItem.new(:name, :parameters, :as_parameters, :collapse_before, :collapse_after, :block, :else_block, :close_options, :else_options)
      def _eval(context)
        helper = as_parameters ? context.get_as_helper(name.to_s) : context.get_helper(name.to_s)
        if helper.nil?
          context.get_helper('helperMissing').apply(context, String.new(name.to_s))
        else
          collapse = {
            helper: CollapseOptions.new(collapse_before, collapse_after),
            else: else_options,
            close: close_options
          }
          if as_parameters
            helper.apply_as(context, parameters, as_parameters, block, else_block, collapse)
          else
            helper.apply(context, parameters, block, else_block, collapse)
          end
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

          if i > 0
            prev = items[i - 1]
            if prev.respond_to?(:close_options)
              value.lstrip! if prev.close_options&.collapse_after
            elsif prev.respond_to?(:collapse_after)
              value.lstrip! if prev.collapse_after
            end
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

    # TODO: Is this still used -- does it need collapse behavior?
    rule(
      comment: simple(:content)
    ) { Tree::Comment.new(content) }

    # TODO: Is this still used?
    rule(
      unsafe_helper_name: simple(:name),
      parameters: subtree(:parameters)
    ) { Tree::EscapedHelper.new(name, parameters) }

    # TODO: Is this still used?
    rule(
      safe_helper_name: simple(:name),
      parameters: subtree(:parameters)
    ) { Tree::Helper.new(name, parameters) }

    rule(
      COLLAPSABLE
    ) { Tree::CollapseOptions.new(collapse_before, collapse_after) }

    rule(COLLAPSABLE.merge(
      unsafe_helper_name: simple(:name),
      parameters: subtree(:parameters)
    )) { Tree::EscapedHelper.new(name, parameters, collapse_before, collapse_after) }

    rule(COLLAPSABLE.merge(
      safe_helper_name: simple(:name),
      parameters: subtree(:parameters)
    )) do
      Tree::Helper.new(name, parameters, nil, collapse_before, collapse_after)
    end

    rule(COLLAPSABLE.merge(
      helper_name: simple(:name),
      block_items: subtree(:block_items),
      close_options: subtree(:close_options)
    )) do
      Tree::Helper.new(name, [], nil, collapse_before, collapse_after, block_items, nil, close_options)
    end

    rule(COLLAPSABLE.merge(
      helper_name: simple(:name),
      block_items: subtree(:block_items),
      else_block_items: subtree(:else_block_items),
      else_options: subtree(:else_options),
      close_options: subtree(:close_options)
    )) do
      Tree::Helper.new(name, [], nil, collapse_before, collapse_after, block_items, else_block_items, close_options, else_options)
    end

    rule(COLLAPSABLE.merge(
      helper_name: simple(:name),
      parameters: subtree(:parameters),
      block_items: subtree(:block_items),
      close_options: subtree(:close_options)
    )) do
      Tree::Helper.new(name, parameters, nil, collapse_before, collapse_after, block_items, nil, close_options)
    end

    rule(COLLAPSABLE.merge(
      helper_name: simple(:name),
      parameters: subtree(:parameters),
      block_items: subtree(:block_items),
      else_block_items: subtree(:else_block_items),
      else_options: subtree(:else_options),
      close_options: subtree(:close_options)
    )) do
      Tree::Helper.new(name, parameters, nil, collapse_before, collapse_after, block_items, else_block_items, close_options, else_options)
    end

    rule(COLLAPSABLE.merge(
      helper_name: simple(:name),
      parameters: subtree(:parameters),
      as_parameters: subtree(:as_parameters),
      block_items: subtree(:block_items),
      close_options: subtree(:close_options)
    )) do
      Tree::Helper.new(name, parameters, as_parameters, collapse_before, collapse_after, block_items, close_options)
    end

    rule(COLLAPSABLE.merge(
      helper_name: simple(:name),
      parameters: subtree(:parameters),
      as_parameters: subtree(:as_parameters),
      block_items: subtree(:block_items),
      else_block_items: subtree(:else_block_items),
      else_options: subtree(:else_options),
      close_options: subtree(:close_options)
    )) do
      Tree::Helper.new(name, parameters, as_parameters, collapse_before, collapse_after, block_items, else_block_items, close_options, else_options)
    end

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
