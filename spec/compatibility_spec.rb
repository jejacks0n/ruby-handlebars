require 'spec_helper'
require 'ruby-handlebars/escapers/dummy_escaper'

describe Handlebars do
  let(:renderer) { Handlebars::Handlebars.new }

  class WhitespacelessString < String
    def ==(other)
      self.strip.gsub(/[\n\s]+/, ' ') == other.strip.gsub(/[\n\s]+/, ' ')
    end
  end

  # TODO: fix up pending specs and get full compatability.

  # These are comprised of examples taken from https://handlebarsjs.com/guide/
  # We want to try to get fully green on these, and any additional examples
  # that work in the playground that don't work in the ruby version.
  #
  # Whitespace is still a work in progress.

  EXAMPLES = {
    "simple-expressions": {
      template: <<~TEMPLATE.strip,
        <p>{{firstname}} {{lastname}}</p>
      TEMPLATE
      input: {
        firstname: "Yehuda",
        lastname: "Katz"
      },
      output: <<~OUTPUT.strip,
        <p>Yehuda Katz</p>
      OUTPUT
    },

    "path-expressions-dot": {
      template: <<~TEMPLATE.strip,
        {{person.firstname}} {{person.lastname}}
      TEMPLATE
      input: {
        person: {
          firstname: "Yehuda",
          lastname: "Katz"
        }
      },
      output: <<~OUTPUT.strip,
        Yehuda Katz
      OUTPUT
    },

    "path-expressions-slash": {
      pending: "This is deprecated, so we could skip it if it's complex.",
      template: <<~TEMPLATE.strip,
        {{person/firstname}} {{person/lastname}}
      TEMPLATE
      input: {
        person: {
          firstname: "Yehuda",
          lastname: "Katz"
        }
      },
      output: <<~OUTPUT.strip,
        Yehuda Katz
      OUTPUT
    },

    "path-expressions-dot-dot": {
      template: <<~TEMPLATE.strip,
        {{#each people}}
          {{../prefix}} {{firstname}}
        {{/each}}
      TEMPLATE
      input: {
        people: [
          {firstname: "Nils"},
          {firstname: "Yehuda"},
        ],
        prefix: "Hello",
      },
      output: WhitespacelessString.new(<<~OUTPUT),
        Hello Nils
        Hello Yehuda
      OUTPUT
    },

    # TODO:
    #
    # Identifiers may be any unicode character except for the following:
    #
    # Whitespace ! " # % & ' ( ) * + , . / ; < = > @ [ \ ] ^ ` { | } ~
    #
    # In addition, the words true, false, null and undefined are only allowed in the first part of a path expression.
    #
    # To reference a property that is not a valid identifier, you can use segment-literal notation, [. You may not include a closing ] in a path-literal, but all other characters are allowed.
    #
    # JavaScript-style strings, " and ', may also be used instead of [ pairs.
    #

    "literal-segments" => {
      pending: "This requires updates to the parser.",
      template: <<~TEMPLATE.strip,
        {{!-- wrong: {{array.0.item}} --}}
        correct: array.[0].item: {{array.[0].item}}

        {{!-- wrong: {{array.[0].item-class}} --}}
        correct: array.[0].[item-class]: {{array.[0].[item-class]}}

        {{!-- wrong: {{./true}}--}}
        correct: ./[true]: {{./[true]}}
      TEMPLATE
      input: {
        array: [
          {
            item: "item1",
            "item-class": "class1",
          },
        ],
        true: "yes",
      },
      output: WhitespacelessString.new(<<~OUTPUT),
        correct: array.[0].item: item1

        correct: array.[0].[item-class]: class1

        correct: ./[true]: yes
      OUTPUT
    },

    "html-escaping" => {
      pending: "the ` and = aren't escaped to &#x60; &#x3D;",
      template: <<~TEMPLATE.strip,
        raw: {{{specialChars}}}
        html-escaped: {{specialChars}}
      TEMPLATE
      input: {
        specialChars: "& < > \" ' ` ="
      },
      output: <<~OUTPUT.strip,
        raw: & < > " ' ` =
        html-escaped: &amp; &lt; &gt; &quot; &#x27; &#x60; &#x3D;
      OUTPUT
    },

    "helper-simple" => {
      template: <<~TEMPLATE.strip,
        {{firstname}} {{loud lastname}}
      TEMPLATE
      input: {
        firstname: "Yehuda",
        lastname: "Katz",
      },
      helpers: {
        loud: Proc.new { |_, str| str.upcase }
      },
      output: <<~OUTPUT.strip,
        Yehuda KATZ
      OUTPUT
    },

    "helper-safestring" => {
      # pending: "The example replaces ' with #x27 (hex) but CGI.escape uses #39 (decimal).",
      template: <<~TEMPLATE.strip,
        {{bold text}}
      TEMPLATE
      input: {
        text: "Isn't this great?"
      },
      helpers: {
        bold: Proc.new do |_, text|
          result = "<b>#{Handlebars.escape_expression(text)}</b>"
          Handlebars::SafeString.new(result)
        end
      },
      output: <<~OUTPUT.strip,
        <b>Isn&#39;t this great?</b>
      OUTPUT
    },

    "helper-multiple-parameters" => {
      template: <<~TEMPLATE.strip,
        {{link "See Website" url}}
      TEMPLATE
      input: {
        url: "https://yehudakatz.com/"
      },
      helpers: {
        link: Proc.new do |context, text, url|
          context.safe(%{<a href="#{context.escape(url)}">#{context.escape(text)}</a>})
        end
      },
      output: <<~OUTPUT.strip,
        <a href="https://yehudakatz.com/">See Website</a>
      OUTPUT
    },

    "helper-dynamic-parameters" => {
      template: <<~TEMPLATE.strip,
        {{link people.text people.url}}
      TEMPLATE
      input: {
        people: {
          firstname: "Yehuda",
          lastname: "Katz",
          url: "https://yehudakatz.com/",
          text: "See Website",
        },
      },
      helpers: {
        link: Proc.new do |_, text, url|
          url = Handlebars.escape_expression(url)
          text = Handlebars.escape_expression(text)
          Handlebars::SafeString.new("<a href='" + url + "'>" + text +"</a>")
        end
      },
      output: <<~OUTPUT.strip,
        <a href='https://yehudakatz.com/'>See Website</a>
      OUTPUT
    },

    "helper-literals" => {
      template: <<~TEMPLATE.strip,
        {{progress "Search" 10.5 false}}
        {{progress "Upload" 90 true}}
        {{progress "Finish" 100 false}}
      TEMPLATE
      helpers: {
        progress: Proc.new do |_, name, percent, stalled, **_options|
          "#{"********************".slice(0, percent / 5.0)} #{percent}% #{name}#{(stalled ? " stalled" : "")}"
        end
      },
      output: <<~OUTPUT.strip,
        ** 10.5% Search
        ****************** 90% Upload stalled
        ******************** 100% Finish
      OUTPUT
    },

    "helper-hash-arguments" => {
      template: <<~TEMPLATE.strip,
        {{link "See Website" href=person.url class="person"}}
      TEMPLATE
      input: {
        person: {
          firstname: "Yehuda",
          lastname: "Katz",
          url: "https://yehudakatz.com/",
        },
      },
      helpers: {
        link: Proc.new do |context, text, **options|
          attributes = options[:hash].map do |key, value|
            %{#{context.escape(key)}="#{context.escape(value)}"}
          end
          context.safe("<a #{attributes.join(" ")}>#{context.escape(text)}</a>")
        end
      },
      output: <<~OUTPUT.strip,
        <a class="person" href="https://yehudakatz.com/">See Website</a>
      OUTPUT
    },

    "helper-data-name-conflict" => {
      pending: "Need to train parser on ./ and this/name, as well as get that baked into context",
      template: <<~TEMPLATE.strip,
        helper: {{name}}
        data: {{./name}} or {{this/name}} or {{this.name}}
      TEMPLATE
      input: {
        name: "Yehuda"
      },
      helpers: {
        name: Proc.new { 'Nils' }
      },
      output: <<~OUTPUT.strip,
        helper: Nils
        data: Yehuda or Yehuda or Yehuda
      OUTPUT
    },

    "sub-expressions" => {
      template: <<~TEMPLATE.strip,
        {{outer-helper (inner-helper 'abc') 'def'}}
      TEMPLATE
      input: {},
      helpers: {
        "outer-helper": Proc.new { |_, v1, v2, **_| "[#{[v1, v2].compact.join('][')}]" },
        "inner-helper": Proc.new { |_, v1, v2, **_| "[#{[v1, v2].compact.join('][')}]" },
      },
      output: <<~OUTPUT.strip,
        [[abc]][def]
      OUTPUT
    },

    "whitespace-control1" => {
      pending: "The parser needs to learn that ^ is inverse/else.",
      template: <<~TEMPLATE.strip,
        {{#each nav ~}}
          <a href="{{url}}">
            {{~#if test}}
              {{~title}}
            {{~^~}}
              Empty
            {{~/if~}}
          </a>
        {{~/each}}
      TEMPLATE
      input: {
        nav: [
          { url: "foo", test: true, title: "bar" },
          { url: "bar" }
        ]
      },
      output: <<~OUTPUT.strip,
        <a href="foo">bar</a><a href="bar">Empty</a>
      OUTPUT
    },

    "whitespace-control2" => {
      pending: "The parser needs to learn that ^ is inverse/else.",
      template: <<~TEMPLATE.strip,
        {{#each nav}}
          <a href="{{url}}">
            {{#if test}}
              {{title}}
            {{^}}
              Empty
            {{/if}}
          </a>
        {{~/each}}
      TEMPLATE
      input: {
        nav: [
          { url: "foo", test: true, title: "bar" },
          { url: "bar" }
        ]
      },
      output: WhitespacelessString.new(<<~OUTPUT),
        <a href="foo">
          bar
        </a>
        <a href="bar">
          Empty
        </a>
      OUTPUT
    },

    "escaping-handlebars-expressions" => {
      # pending: "This is not understood by the parser yet.",
      template: <<~TEMPLATE.strip,
        \\{{escaped1}}
        {{{{raw}}}}
          {{escaped2}}
        {{{{/raw}}}}
      TEMPLATE
      input: {
        escaped1: 'asdasdasd',
      },
      helpers: {
        raw: Proc.new do |context, block:, **options|
          block.fn(context)
        end
      },
      output: WhitespacelessString.new(<<~OUTPUT),
        {{escaped1}}
        {{escaped2}}
      OUTPUT
    },

    "partials/basic" => {
      template: <<~TEMPLATE.strip,
        {{> myPartial }}
      TEMPLATE
      input: { prefix: "Hello" },
      partials: {
        myPartial: "{{prefix}}"
      },
      output: <<~OUTPUT.strip,
        Hello
      OUTPUT
    },

    "partials/dynamic" => {
      pending: "The parser doesn't understand how to parse the () in a partial name.",
      template: <<~TEMPLATE.strip,
        {{> (whichPartial) }}
      TEMPLATE
      helpers: {
        whichPartial: Proc.new { "dynamicPartial" }
      },
      partials: {
        dynamicPartial: "Dynamo!"
      },
      output: <<~OUTPUT.strip,
        Dynamo!
      OUTPUT
    },

    "partials/variable" => {
      pending: "Several things here -- parsing (), calling helpers, and lookup accessing .",
      template: <<~TEMPLATE.strip,
        {{> (lookup . 'myVariable') }}
      TEMPLATE
      input: {
        myVariable: "lookupMyPartial"
      },
      partials: {
        lookupMyPartial: "Found!"
      },
      output: <<~OUTPUT.strip,
        Found!
      OUTPUT
    },

    "partials/other-context" => {
      pending: "Not entirely sure -- looks like a parsing issue with the param to the partial",
      template: <<~TEMPLATE.strip,
        {{> myPartial myOtherContext }}
      TEMPLATE
      input: {
        myOtherContext: {
          information: "Interesting!",
        },
      },
      partials: {
        myPartial: "{{information}}"
      },
      output: <<~OUTPUT.strip,
        Interesting!
      OUTPUT
    },

    "partials/parameters" => {
      template: <<~TEMPLATE.strip,
        {{> myPartial parameter=favoriteNumber }}
      TEMPLATE
      input: {
        favoriteNumber: 123
      },
      partials: {
        myPartial: "The result is {{parameter}}"
      },
      output: <<~OUTPUT.strip,
        The result is 123
      OUTPUT
    },

    "partials/parent-context" => {
      template: <<~TEMPLATE.strip,
        {{#each people}}
          {{> myPartial prefix=../prefix firstname=firstname lastname=lastname}}.
        {{/each}}
      TEMPLATE
      input: {
        people: [
          {
            firstname: "Nils",
            lastname: "Knappmeier",
          },
          {
            firstname: "Yehuda",
            lastname: "Katz",
          },
        ],
        prefix: "Hello",
      },
      partials: {
        myPartial: "{{prefix}}, {{firstname}} {{lastname}}"
      },
      output: WhitespacelessString.new(<<~OUTPUT),
        Hello, Nils Knappmeier.
        Hello, Yehuda Katz.
      OUTPUT
    },

    "partials/failover" => {
      template: <<~TEMPLATE.strip,
        {{#> myPartial }}
          Failover content
        {{/myPartial}}
      TEMPLATE
      output: WhitespacelessString.new(<<~OUTPUT.strip),
        Failover content
      OUTPUT
    },

    "partials/partial-block" => {
      template: <<~TEMPLATE.strip,
        {{#> layout }}
        My Content
        {{/layout}}
      TEMPLATE
      partials: {
        layout: "Site Content {{> @partial-block }}"
      },
      output: WhitespacelessString.new(<<~OUTPUT),
        Site Content My Content
      OUTPUT
    },

    "partials/inline" => {
      template: <<~TEMPLATE.strip,
        {{#*inline "myPartial"}}
          My Content
        {{/inline}}
        {{#each people}}
          {{> myPartial}}
        {{/each}}
      TEMPLATE
      input: {
        people: [
          { firstname: "Nils" },
          { firstname: "Yehuda" },
        ],
      },
      output: WhitespacelessString.new(<<~OUTPUT),
        My Content
        My Content
      OUTPUT
    },

    "partials/inline-blocks" => {
      template: <<~TEMPLATE.strip,
        {{#> layout}}
          {{#*inline "nav"}}
            My Nav
          {{/inline}}
          {{#*inline "content"}}
            My Content
          {{/inline}}
        {{/layout}}
      TEMPLATE
      partials: {
        layout: <<~PARTIAL.strip,
          <div class="nav">
            {{> nav}}
          </div>
          <div class="content">
            {{> content}}
          </div>
        PARTIAL
      },
      output: WhitespacelessString.new(<<~OUTPUT),
        <div class="nav">
              My Nav
        </div>
        <div class="content">
              My Content
        </div>
      OUTPUT
    },

    "block-helpers/basic-block" => {
      template: <<~TEMPLATE.strip,
        <div class="entry">
          <h1>{{title}}</h1>
          <div class="body">
            {{#noop}}{{body}}{{/noop}}
          </div>
        </div>
      TEMPLATE
      input: {
        title: "title content",
        body: "body content"
      },
      helpers: {
        noop: Proc.new do |context, block:, **_options|
          block.fn(context)
        end
      },
      output: <<~OUTPUT.strip,
        <div class="entry">
          <h1>title content</h1>
          <div class="body">
            body content
          </div>
        </div>
      OUTPUT
    },

    "block-helpers/context-access" => {
      pending: "Need to implement logic to handle ./ notation.",
      template: <<~TEMPLATE.strip,
        {{./noop}}
      TEMPLATE
      input: {
        noop: "this is noop content",
      },
      helpers: {
        noop: Proc.new { }
      },
      output: <<~OUTPUT.strip,
        this is noop content
      OUTPUT
    },

    "block-helpers/basic-variation" => {
      template: <<~TEMPLATE.strip,
        <div class="entry">
          <h1>{{title}}</h1>
          <div class="body">
            {{#bold}}{{body}}{{/bold}}
          </div>
        </div>
      TEMPLATE
      input: {
        title: "title content",
        body: "body content"
      },
      helpers: {
        bold: Proc.new do |context, block:|
          Handlebars::SafeString.new('<div class="mybold">' + block.fn(context) + "</div>");
        end
      },
      output: <<~OUTPUT.strip,
        <div class="entry">
          <h1>title content</h1>
          <div class="body">
            <div class="mybold">body content</div>
          </div>
        </div>
      OUTPUT
    },

    "helper-simple" => {
      template: <<~TEMPLATE.strip,
        <div class="entry">
          <h1>{{title}}</h1>
          {{#with story}}
            <div class="intro">{{{intro}}}</div>
            <div class="body">{{{body}}}</div>
          {{/with}}
        </div>
      TEMPLATE
      input: {
        title: "First Post",
        story: {
          intro: "Before the jump",
          body: "After the jump"
        }
      },
      helpers: {},
      output: WhitespacelessString.new(<<~OUTPUT),
        <div class="entry">
          <h1>First Post</h1>
          <div class="intro">Before the jump</div>
          <div class="body">After the jump</div>
        </div>
      OUTPUT
    },

    # TODO: Add more of the helper examples in here.

    "raw-blocks" => {
      template: <<~TEMPLATE.strip,
        {{{{raw-loud}}}}
          {{bar}}
        {{{{/raw-loud}}}}
      TEMPLATE
      helpers: {
        "raw-loud": Proc.new do |context, block:, **options|
          block.fn(context).to_s.upcase
        end
      },
      output: WhitespacelessString.new(<<~OUTPUT),
        {{BAR}}
      OUTPUT
    },

    "hook-helper-missing" => {
      pending: "We need to improve the compatibility of helper method missing behavior.",
      template: <<~TEMPLATE.strip,
        {{foo}}
        {{foo true}}
        {{foo 2 true}}
        {{#foo true}}{{/foo}}
        {{#foo}}rendered{{/foo}}
      TEMPLATE
      helpers: {
        helperMissing: Proc.new do |_, *args, name:, **options|
          Handlebars::SafeString.new("Missing: #{name}(#{args.join(',')})")
        end
      },
      output: <<~OUTPUT.strip,
        Missing: foo()
        Missing: foo(true)
        Missing: foo(2,true)
        Missing: foo(true)
        rendered
      OUTPUT
    },

    "hook-helper-missing-default-no-param" => {
      pending: "We need to improve the compatibility of helper method missing behavior.",
      template: <<~TEMPLATE.strip,
        some_{{foo}}mustache
        some_{{#foo}}abc{{/foo}}block
      TEMPLATE
      output: <<~OUTPUT.strip,
        some_mustache
        some_block
      OUTPUT
    },

    "hook-helper-missing-default-param" => {
      template: <<~TEMPLATE.strip,
        {{foo bar}}
        {{#foo bar}}abc{{/foo}}
      TEMPLATE
      error: [Handlebars::UnknownHelper, "Helper \"foo\" does not exist"]
    },

    "hook-block-helper-missing" => {
      pending: "Implement the blockHelperMissing helper and behavior.",
      template: <<~TEMPLATE.strip,
        {{#person}}
          {{firstname}} {{lastname}}
        {{/person}}
      TEMPLATE
      input: {
        person: {
          firstname: "Yehuda",
          lastname: "Katz",
        },
      },
      helpers: {
        blockHelperMissing: Proc.new do |context, block:, **options|
          %{Helper '#{options.name}' not found. Printing block: #{block.fn(context)}}
        end
      },
      output: <<~OUTPUT.strip,
        Helper 'person' not found. Printing block:   Yehuda Katz
      OUTPUT
    },

    "hook-block-helper-missing-default" => {
      pending: "Implement the blockHelperMissing helper and behavior.",
      template: <<~TEMPLATE.strip,
        {{#person}}
          {{firstname}} {{lastname}}
        {{/person}}
      TEMPLATE
      input: {
        person: {
          firstname: "Yehuda",
          lastname: "Katz",
        },
      },
      output: <<~OUTPUT.strip,
        Yehuda Katz
      OUTPUT
    },

    "hook-block-helper-missing-default-param" => {
      # TODO: This causes a lookup exception in handlebars.
      #       Should it work here?
      template: <<~TEMPLATE.strip,
        {{#person foo}}
          {{firstname}} {{lastname}}
        {{/person}}
      TEMPLATE
      input: {
        person: {
          firstname: "Yehuda",
          lastname: "Katz",
        },
      },
      output: "\n  Yehuda Katz\n"
    },
  }

  EXAMPLES.each do |example_name, scenario|
    puts example_name
    it "passes on the #{example_name} scenario" do
      pending(scenario[:pending]) if scenario[:pending]
      action = Proc.new do
        render(scenario[:template], scenario[:input]) do |renderer|
          scenario[:partials]&.each { |name, content| renderer.register_partial(name, content) }
          scenario[:helpers]&.each { |name, proc| renderer.register_helper(name, &proc) }
        end
      end

      if scenario[:error]
        expect(action).to raise_error(*scenario[:error])
      else
        expect(scenario[:output]).to eq(action.call)
      end
    end
  end

  def render(template, input = {})
    compiled_template = renderer.compile(template)
    yield renderer, compiled_template if block_given?
    compiled_template.call(input)
  end
end
