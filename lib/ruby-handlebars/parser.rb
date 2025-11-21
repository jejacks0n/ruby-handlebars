module Handlebars
  class Parser < Parslet::Parser
    rule(:space)         { match('\s').repeat(1) }
    rule(:space?)        { space.maybe }
    rule(:dot)           { str('.') }
    rule(:gt)            { str('>') }
    rule(:hash)          { str('#') }
    rule(:slash)         { str('/') }
    rule(:backslash)     { str('\\') }
    rule(:ocurly)        { str('{') }
    rule(:ccurly)        { str('}') }
    rule(:pipe)          { str('|') }
    rule(:eq)            { str('=') }
    rule(:bang)          { str('!') }
    rule(:at)            { str('@') }
    rule(:tilde)         { str('~') }
    rule(:caret)         { str('^') }
    rule(:else_kw)       { str('else') | caret }
    rule(:as_kw)         { str('as') }

    rule(:docurly)       { ocurly >> ocurly >> tilde.maybe.as(:collapse_before) }
    rule(:dccurly)       { space? >> tilde.maybe.as(:collapse_after) >> ccurly >> ccurly }
    rule(:tocurly)       { ocurly >> ocurly >> ocurly >> tilde.maybe.as(:collapse_before) }
    rule(:tccurly)       { space? >> tilde.maybe.as(:collapse_after) >> ccurly >> ccurly >> ccurly }
    rule(:qocurly)       { ocurly >> ocurly >> ocurly >> ocurly }
    rule(:qccurly)       { ccurly >> ccurly >> ccurly >> ccurly }

    rule(:else_absent?)  { (else_kw >> space? >> dccurly).absent? }
    rule(:as_absent?)    { (as_kw >> space? >> pipe).absent? }

    rule(:identifier)    do
      else_absent? >>
      at.maybe >>
      str("../").repeat.maybe >>
      match['@\-a-zA-Z0-9_\.\?'].repeat(1)
    end
    rule(:directory)     { else_absent? >> match['@\-a-zA-Z0-9_\/\?'].repeat(1) }

    # TODO: why is the else_kw here?
    rule(:path)          { identifier >> (dot >> (identifier | else_kw)).repeat }

    rule(:nocurly)       { match('[^{}]') }
    rule(:noocurly)       { match('[^{]') }
    rule(:noccurly)       { match('[^}]') }
    rule(:eof)           { any.absent? }

    rule(:sq_string)     { str("'") >> match("[^']").repeat.maybe.as(:str_content) >> str("'") }
    rule(:dq_string)     { str('"') >> match('[^"]').repeat.maybe.as(:str_content) >> str('"') }
    rule(:string)        { sq_string | dq_string }

    rule(:unsafe_helper) { space? >> identifier.as(:unsafe_helper_name) >> (space? >> parameters.as(:parameters)).maybe >> space? }
    rule(:safe_helper)   { space? >> identifier.as(:safe_helper_name) >> (space? >> parameters.as(:parameters)).maybe >> space? }

    rule(:parameter)     { as_absent? >> (argument.as(:named_parameter) | (path | string).as(:parameter_name) | (str('(') >> safe_helper >> str(')'))) }
    rule(:parameters)    { parameter >> (space >> parameter).repeat }
    rule(:as_parameters) { space >> as_kw >> space >> pipe >> space? >> parameters.as(:as_parameters) >> space? >> pipe }

    rule(:argument)      { identifier.as(:key) >> space? >> eq >> space? >> parameter.as(:value) }
    rule(:arguments)     { argument >> (space >> argument).repeat }

    rule(:template_content) do
      (
        (backslash >> ocurly).absent? >>
        (
          nocurly.repeat(1) | # A sequence of non-curlies
          ocurly >> nocurly | # Opening curly that doesn't start a {{}}
          ccurly            | # Closing curly that is not inside a {{}}
          ocurly >> eof       # Opening curly that doesn't start a {{}} because it's the end
        )
      ).repeat(1).as(:template_content)
    end

    rule(:raw_template_content) do
      (
        nocurly.repeat(1)                      | # A sequence of non-curlies
        ocurly >> noocurly                     | # Opening curly that doesn't start a {{}}
        ocurly >> ocurly >> noocurly           | # ..
        ocurly >> ocurly >> ocurly >> noocurly | # ..
        ccurly                                 | # Closing curly that is not inside a {{}}
        ocurly >> eof                            # Opening curly that doesn't start a {{}} because it's the end
      ).repeat(1).as(:raw_template_content)
    end

    rule(:escaped_replacement) do
      backslash >>
      ((ocurly >> ocurly) | (ocurly >> ocurly >> ocurly)).as(:open_curly) >>
      space? >>
      (
        nocurly.repeat(1)  | # A sequence of non-curlies
        ocurly >> noocurly | # Opening curly that doesn't start a {{}}
        ccurly >> noccurly   # Closing curly that is not inside a {{}}
      ).repeat(1).as(:escaped_content) >>
      ((ccurly >> ccurly) | (ccurly >> ccurly >> ccurly)).as(:close_curly)
    end

    rule(:unsafe_replacement) do
      docurly >>
      space? >>
      path.as(:replaced_unsafe_item) >>
      dccurly
    end

    rule(:safe_replacement) do
      tocurly >>
      space? >>
      path.as(:replaced_safe_item) >>
      tccurly
    end

    rule(:comment) do
      docurly >>
      bang >>
      space? >>
      nocurly.repeat.maybe.as(:comment) >>
      dccurly
    end

    rule(:partial) do
      docurly >>
      gt >>
      space? >>
      directory.as(:partial_name) >>
      space? >>
      arguments.as(:arguments).maybe >>
      dccurly
    end

    rule(:block_partial) {
      docurly >>
      hash >>
      gt >>
      space? >>
      directory.capture(:close_name).as(:partial_name) >>
      space? >>
      arguments.as(:arguments).maybe >>
      space? >>
      dccurly >>
      scope {
        block
      } >>
      dynamic { |src, scope|
        (
          docurly >>
          slash >>
          space? >>
          str(scope.captures[:close_name]) >>
          space? >>
          dccurly
        ).as(:close_options)
      }
    }

    rule(:helper) do
      (docurly >> unsafe_helper >> dccurly) |
      (tocurly >> safe_helper >> tccurly)
    end

    rule(:block_helper) do
      docurly >>
      hash >>
      space? >>
      (str('*inline') | identifier).capture(:close_name).as(:helper_name) >>
      (space >> parameters.as(:parameters)).maybe >>
      as_parameters.maybe >>
      space? >>
      dccurly >>
      scope {
        block
      } >>
      scope {
        (
          docurly >>
          space? >>
          else_kw >>
          dccurly
        ).as(:else_options) >>
        scope {
          block_item.repeat.as(:else_block_items)
        }
      }.maybe >>
      dynamic do |src, scope|
        (
          docurly >>
          slash >>
          space? >>
          str(scope.captures[:close_name].to_s.gsub(/^\*/, '')) >>
          space? >>
          dccurly
        ).as(:close_options)
      end
    end

    rule(:raw_block) do
      qocurly >>
      space? >>
      identifier.capture(:close_name).as(:raw_helper_name) >>
      (space >> parameters.as(:parameters)).maybe >>
      as_parameters.maybe >>
      space? >>
      qccurly >>
      scope {
        raw_template_content.repeat(1).as(:block_items)
      } >>
      dynamic do |src, scope|
        qocurly >>
        slash >>
        space? >>
        str(scope.captures[:close_name]) >>
        space? >>
        qccurly
      end
    end

    rule(:block_item) do
      template_content |
      comment |
      escaped_replacement |
      unsafe_replacement |
      safe_replacement |
      partial |
      block_partial |
      helper |
      block_helper |
      raw_block
    end

    rule(:block) do
      block_item.repeat.as(:block_items)
    end

    root :block
  end
end
