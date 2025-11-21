module Handlebars
  module Tree
    class TreeItem < Struct
      def eval(context)
        _eval(context)
      end
    end

    class TemplateContent < TreeItem.new(:content, :prefix, :suffix)
      def _eval(context)
        [prefix, content, suffix].join
      end
    end

    class Replacement < TreeItem.new(:item, :collapse_before, :collapse_after)
      def _eval(context)
        if context.get_helper(item.to_s).nil?
          context.get(item.to_s)
        else
          context.get_helper(item.to_s).apply(item.to_s, context)
        end
      end
    end

    class EscapedReplacement < Replacement
      def _eval(context)
        result = super(context)
        context.escape(result)
      end
    end

    class String < TreeItem.new(:content)
      def _eval(context)
        content
      end
    end

    class Parameter < TreeItem.new(:name)
      def _eval(context)
        if name.is_a?(Parslet::Slice)
          context.get(name)
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
        helper_name = name.to_s
        helper = context.get_helper(helper_name, as: as_parameters)
        if helper.nil?
          # check the context for a matching key.
          if context.get(helper_name)
            # swap the helper to "with"
            helper = context.get_helper('with')
            self.parameters = Parameter.new(Parslet::Slice.new(0, name.to_s))
          else
            # fall back to the missing helper.
            helper = context.get_helper('helperMissing')
          end
        end

        collapse = {
          helper: CollapseOptions.new(collapse_before, collapse_after),
          else: else_options,
          close: close_options
        }

        if as_parameters
          helper.apply_as(helper_name, context, parameters, as_parameters, block, else_block, collapse)
        else
          helper.apply(helper_name, context, parameters, block, else_block, collapse)
        end
      end
    end

    class EscapedHelper < Helper
      def _eval(context)
        result = super(context)
        context.escape(result)
      end
    end

    class Partial < TreeItem.new(:partial_name, :arguments, :collapse_before, :collapse_after, :block, :close_options)
      def _eval(context)
        [arguments].flatten.compact.map(&:values).map do |vals|
          context.add_item(vals.first.to_s, vals.last._eval(context))
        end

        tree_block = Tree::Block.new(block) if block
        result = tree_block&.fn(context)

        context.with_nested_temporary_context('@partial-block': result) do
          return context.get('@../partial-block') if partial_name == '@partial-block'

          partial = context.get_partial(partial_name, raise_on_missing: block.nil?)
          if partial
            partial.call_with_context(context)
          elsif block
            result
          end
        end
      end
    end

    class Comment < TreeItem.new(:comment, :collapse_before, :collapse_after)
      def _eval(context)
      end
    end

    class Block < TreeItem.new(:items)
      UnknownBlock = Class.new(StandardError)

      def _eval(context)
        items.each_with_index.map do |item, i|
          raise UnknownBlock, "Missing transform for #{item.inspect}" if item.is_a?(Hash)
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

    rule(str_content: simple(:content)) { Tree::String.new(content) }
    rule(parameter_name: simple(:name)) { Tree::Parameter.new(name) }
    rule(COLLAPSABLE) { Tree::CollapseOptions.new(collapse_before, collapse_after) }
    rule(block_items: subtree(:block_items)) { Tree::Block.new(block_items) }
    rule(else_block_items: subtree(:else_block_items)) { Tree::Block.new(block_items) }

    # General

    rule(
      template_content: simple(:content)
    ) { Tree::TemplateContent.new(content) }

    rule(
      raw_template_content: simple(:content)
    ) { Tree::TemplateContent.new(content) }

    rule(
      open_curly: simple(:open_curly),
      close_curly: simple(:close_curly),
      escaped_content: simple(:escaped_content)
    ) { Tree::TemplateContent.new(escaped_content, open_curly, close_curly) }

    rule(COLLAPSABLE.merge(
      replaced_unsafe_item: simple(:item)
    )) { Tree::EscapedReplacement.new(item, collapse_before, collapse_after) }

    rule(COLLAPSABLE.merge(
      replaced_safe_item: simple(:item)
    )) { Tree::Replacement.new(item, collapse_before, collapse_after) }

    rule(COLLAPSABLE.merge(
      comment: simple(:content)
    )) { Tree::Comment.new(content, collapse_before, collapse_after) }

    # Partials

    rule(COLLAPSABLE.merge(
      partial_name: simple(:name)
    )) { Tree::Partial.new(name, nil, collapse_before, collapse_after) }

    rule(COLLAPSABLE.merge(
      partial_name: simple(:name),
      arguments: subtree(:arguments)
    )) { Tree::Partial.new(name, arguments, collapse_before, collapse_after) }

    rule(COLLAPSABLE.merge(
      partial_name: simple(:name),
      block_items: subtree(:block_items),
      close_options: subtree(:close_options)
    )) { Tree::Partial.new(name, nil, collapse_before, collapse_after, block_items, close_options) }

    rule(COLLAPSABLE.merge(
      partial_name: simple(:name),
      arguments: subtree(:arguments),
      block_items: subtree(:block_items),
      close_options: subtree(:close_options)
    )) { Tree::Partial.new(name, arguments, collapse_before, collapse_after, block_items, close_options) }

    # Helpers

    rule(
      safe_helper_name: simple(:name)
    ) { Tree::Helper.new(name) }

    rule(
      safe_helper_name: simple(:name),
      parameters: subtree(:parameters)
    ) { Tree::Helper.new(name, parameters) }

    rule(
      raw_helper_name: simple(:name),
      block_items: subtree(:block_items)
    ) { Tree::Helper.new(name, [], nil, nil, nil, block_items) }

    rule(
      raw_helper_name: simple(:name),
      parameters: subtree(:parameters),
      block_items: subtree(:block_items)
    ) { Tree::Helper.new(name, parameters, nil, nil, nil, block_items) }

    rule(COLLAPSABLE.merge(
      unsafe_helper_name: simple(:name),
    )) { Tree::EscapedHelper.new(name, [], collapse_before, collapse_after) }

    rule(COLLAPSABLE.merge(
      unsafe_helper_name: simple(:name),
      parameters: subtree(:parameters)
    )) { Tree::EscapedHelper.new(name, parameters, collapse_before, collapse_after) }

    rule(COLLAPSABLE.merge(
      safe_helper_name: simple(:name),
    )) { Tree::Helper.new(name, [], nil, collapse_before, collapse_after) }

    rule(COLLAPSABLE.merge(
      safe_helper_name: simple(:name),
      parameters: subtree(:parameters)
    )) { Tree::Helper.new(name, parameters, nil, collapse_before, collapse_after) }

    rule(COLLAPSABLE.merge(
      helper_name: simple(:name),
      block_items: subtree(:block_items),
      close_options: subtree(:close_options)
    )) { Tree::Helper.new(name, [], nil, collapse_before, collapse_after, block_items, nil, close_options) }

    rule(COLLAPSABLE.merge(
      helper_name: simple(:name),
      block_items: subtree(:block_items),
      else_block_items: subtree(:else_block_items),
      else_options: subtree(:else_options),
      close_options: subtree(:close_options)
    )) { Tree::Helper.new(name, [], nil, collapse_before, collapse_after, block_items, else_block_items, close_options, else_options) }

    rule(COLLAPSABLE.merge(
      helper_name: simple(:name),
      parameters: subtree(:parameters),
      block_items: subtree(:block_items),
      close_options: subtree(:close_options)
    )) { Tree::Helper.new(name, parameters, nil, collapse_before, collapse_after, block_items, nil, close_options) }

    rule(COLLAPSABLE.merge(
      helper_name: simple(:name),
      parameters: subtree(:parameters),
      block_items: subtree(:block_items),
      else_block_items: subtree(:else_block_items),
      else_options: subtree(:else_options),
      close_options: subtree(:close_options)
    )) { Tree::Helper.new(name, parameters, nil, collapse_before, collapse_after, block_items, else_block_items, close_options, else_options) }

    rule(COLLAPSABLE.merge(
      helper_name: simple(:name),
      parameters: subtree(:parameters),
      as_parameters: subtree(:as_parameters),
      block_items: subtree(:block_items),
      close_options: subtree(:close_options)
    )) { Tree::Helper.new(name, parameters, as_parameters, collapse_before, collapse_after, block_items, close_options) }

    rule(COLLAPSABLE.merge(
      helper_name: simple(:name),
      parameters: subtree(:parameters),
      as_parameters: subtree(:as_parameters),
      block_items: subtree(:block_items),
      else_block_items: subtree(:else_block_items),
      else_options: subtree(:else_options),
      close_options: subtree(:close_options)
    )) { Tree::Helper.new(name, parameters, as_parameters, collapse_before, collapse_after, block_items, else_block_items, close_options, else_options) }
  end
end
