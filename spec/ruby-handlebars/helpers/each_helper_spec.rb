require 'spec_helper'
require_relative './shared'

describe Handlebars::Helpers::EachHelper do
  let(:subject) { Handlebars::Helpers::EachHelper }
  let(:hbs) { Handlebars::Handlebars.new }
  let(:ctx) { Handlebars::Context.new(hbs, {}) }

  it_behaves_like "a registerable helper", "each"

  context '.apply' do
    include_context "shared apply helper"

    let(:values) { [Handlebars::Tree::String.new('a'), Handlebars::Tree::String.new('b'), Handlebars::Tree::String.new('c') ]}

    it 'applies the block on all values' do
      subject.apply(ctx, values, hash: {}, block: block, else_block: else_block, collapse: {})

      expect(block).to have_received(:fn).exactly(3).times
      expect(else_block).not_to have_received(:fn)
    end

    context 'when values is nil' do
      let(:values) { nil }

      it 'uses the else_block if provided' do
        subject.apply(ctx, values, hash: {}, block: block, else_block: else_block, collapse: {})

        expect(block).not_to have_received(:fn)
        expect(else_block).to have_received(:fn).once
      end

      it 'returns nil if no else_block is provided' do
        expect(subject.apply(ctx, values, hash: {}, block: block, else_block: nil, collapse: {})).to be nil
      end
    end

    context 'when values is empty' do
      let(:values) { [] }

      it 'uses the else_block if provided' do
        subject.apply(ctx, values, hash: {}, block: block, else_block: else_block, collapse: {})

        expect(block).not_to have_received(:fn)
        expect(else_block).to have_received(:fn).once
      end

      it 'returns nil if no else_block is provided' do
        expect(subject.apply(ctx, values, hash: {}, block: block, else_block: nil, collapse: {})).to be nil
      end
    end
  end

  context 'integration' do
    include_context "shared helpers integration tests"

    let(:ducks) {[{name: 'Huey'}, {name: 'Dewey'}, {name: 'Louis'}]}

    it 'simple case' do
      template = [
        "<ul>",
        "{{#each items}}  <li>{{this.name}}</li>",
        "{{/each}}</ul>"
      ].join("\n")

      data = {items: ducks}
      expect(evaluate(template, data)).to eq([
        "<ul>",
        "  <li>Huey</li>",
        "  <li>Dewey</li>",
        "  <li>Louis</li>",
        "</ul>"
      ].join("\n"))

      data = {items: []}
      expect(evaluate(template, data)).to eq([
        "<ul>",
        "</ul>"
      ].join("\n"))
    end

    it 'considers not found items as an empty list and does not raise an error' do
      template = [
        "<ul>",
        "{{#each stuff}}  <li>{{this.name}}</li>",
        "{{/each}}</ul>"
      ].join("\n")

      expect(evaluate(template, {})).to eq([
        "<ul>",
        "</ul>"
      ].join("\n"))
    end

    it 'considers not found items as an empty list and uses else block if provided' do
      template = [
        "<ul>",
        "{{#each stuff}}  <li>{{this.name}}</li>",
        "{{else}}  <li>No stuff found....</li>",
        "{{/each}}</ul>"
      ].join("\n")

      expect(evaluate(template, {})).to eq([
        "<ul>",
        "  <li>No stuff found....</li>",
        "</ul>"
      ].join("\n"))
    end

    it 'works with non-hash data' do
      template = [
        "<ul>",
        "{{#each items}}  <li>{{this.name}}</li>",
        "{{/each}}</ul>"
      ].join("\n")

      data = {items: ducks}
      expect(evaluate(template, data)).to eq([
        "<ul>",
        "  <li>Huey</li>",
        "  <li>Dewey</li>",
        "  <li>Louis</li>",
        "</ul>"
      ].join("\n"))

      data = {items: []}
      expect(evaluate(template, data)).to eq([
        "<ul>",
        "</ul>"
      ].join("\n"))
    end

    it 'using an else statement' do
      template = [
        "<ul>",
        "{{#each items}}  <li>{{this.name}}</li>",
        "{{else}}  <li>No ducks to display</li>",
        "{{/each}}</ul>"
      ].join("\n")

      data = {items: ducks}
      expect(evaluate(template, data)).to eq([
        "<ul>",
        "  <li>Huey</li>",
        "  <li>Dewey</li>",
        "  <li>Louis</li>",
        "</ul>"
      ].join("\n"))

      data = {items: []}
      expect(evaluate(template, data)).to eq([
        "<ul>",
        "  <li>No ducks to display</li>",
        "</ul>"
      ].join("\n"))
    end

    it 'imbricated' do
      data = {people: [
        {
          name: 'Huey',
          email: 'huey@junior-woodchucks.example.com',
          phones: ['1234', '5678'],
        },
        {
          name: 'Dewey',
          email: 'dewey@junior-woodchucks.example.com',
          phones: ['4321'],
        }
      ]}

      template = [
        "People:",
        "<ul>",
        "  {{#each people}}",
        "  <li>",
        "    <ul>",
        "      <li>Name: {{this.name}}</li>",
        "      <li>Phones: {{#each this.phones}} {{this}} {{/each}}</li>",
        "      <li>email: {{this.email}}</li>",
        "    </ul>",
        "  </li>",
        "  {{else}}",
        "  <li>No one to display</li>",
        "  {{/each}}",
        "</ul>"
      ].join("\n")

      expect(evaluate(template, data)).to eq([
        "People:",
        "<ul>",
        "  ",
        "  <li>",
        "    <ul>",
        "      <li>Name: Huey</li>",
        "      <li>Phones:  1234  5678 </li>",
        "      <li>email: huey@junior-woodchucks.example.com</li>",
        "    </ul>",
        "  </li>",
        "  ",
        "  <li>",
        "    <ul>",
        "      <li>Name: Dewey</li>",
        "      <li>Phones:  4321 </li>",
        "      <li>email: dewey@junior-woodchucks.example.com</li>",
        "    </ul>",
        "  </li>",
        "  ",
        "</ul>"
      ].join("\n"))
    end

    context "white space" do
      let(:data) { {items: ['a', 'b', 'c']} }

      it "can be stripped in simple cases" do
        result = evaluate("[ {{~#each items}}  {{this}}  {{/each~}} ]", data)
        expect(result).to eq("[  a    b    c  ]")

        result = evaluate("[ {{~#each items}}  {{~this~}}  {{/each~}} ]", data)
        expect(result).to eq("[abc]")

        result = evaluate("[ {{~#each items~}}  {{this}}  {{~/each~}} ]", data)
        expect(result).to eq("[abc]")
      end

      it "can be stripped in cases with else" do
        result = evaluate("[ {{~#each items~}}  {{this}}  {{else}}  otherwise  {{/each~}} ]", data)
        expect(result).to eq("[a  b  c  ]")

        result = evaluate("[ {{~#each items~}}  {{this}}  {{~else}}  otherwise  {{/each~}} ]", data)
        expect(result).to eq("[abc]")

        result = evaluate("[ {{~#each nothing}} x {{else}}  otherwise  {{/each~}} ]")
        expect(result).to eq("[  otherwise  ]")

        result = evaluate("[ {{~#each nothing}} x {{else~}}  otherwise  {{~/each~}} ]")
        expect(result).to eq("[otherwise]")

        result = evaluate("[ {{~#each nothing}} x {{~/each~}} ]")
        expect(result).to eq("[]")
      end
    end

    context 'special variables' do
      it '@first' do
        template = [
          "{{#each items}}",
          "{{this}}",
          "{{#if @first}}",
          " first",
          "{{/if}}\n",
          "{{/each}}"
        ].join
        expect(evaluate(template, {items: %w(a b c)})).to eq("a first\nb\nc\n")
      end

      it '@last' do
        template = [
          "{{#each items}}",
          "{{this}}",
          "{{#if @last}}",
          " last",
          "{{/if}}\n",
          "{{/each}}"
        ].join
        expect(evaluate(template, {items: %w(a b c)})).to eq("a\nb\nc last\n")
      end

      it '@index' do
        template = [
          "{{#each items}}",
          "{{this}} {{@index}}\n",
          "{{/each}}"
        ].join
        expect(evaluate(template, {items: %w(a b c)})).to eq("a 0\nb 1\nc 2\n")
      end

      it "understands ../ traversal" do
        template = <<~TEMPLATE.strip
          {{#each items}}
            {{this.name}}
            {{#each subitems}}
              {{this.name}}
              {{../name}}
            {{/each}}
          {{/each}}
        TEMPLATE
        data = {
          items: [
            {name: 'level1_item1', subitems: [{name: 'level2_item1_subitem1'}, {name: 'level2_item1_subitem2'}]},
            {name: 'level1_item2', subitems: [{name: 'level2_item2_subitem1'}, {name: 'level2_item2_subitem2'}]},
            {name: 'level1_item3', subitems: []}
          ]
        }
        expect(evaluate(template, data)).to eq([
          "",
          "  level1_item1\n  ",
          "    level2_item1_subitem1",
          "    level1_item1\n  ",
          "    level2_item1_subitem2",
          "    level1_item1\n  ",
          "",
          "  level1_item2\n  ",
          "    level2_item2_subitem1",
          "    level1_item2\n  ",
          "    level2_item2_subitem2",
          "    level1_item2\n  ",
          "",
          "  level1_item3\n  ",
          "",
        ].join("\n"))
      end
    end
  end

  context 'integration with "as |value|" notation' do
    include_context "shared helpers integration tests"

    let(:ducks) {[{name: 'Huey'}, {name: 'Dewey'}, {name: 'Louis'}]}

    it 'simple case' do
      template = [
        "<ul>",
        "{{#each items as |item|}}  <li>{{item.name}}</li>",
        "{{/each}}</ul>"
      ].join("\n")

      data = {items: ducks}
      expect(evaluate(template, data)).to eq([
        "<ul>",
        "  <li>Huey</li>",
        "  <li>Dewey</li>",
        "  <li>Louis</li>",
        "</ul>"
      ].join("\n"))
    end

    it 'imbricated' do
      data = {people: [
        {
          name: 'Huey',
          email: 'huey@junior-woodchucks.example.com',
          phones: ['1234', '5678'],
        },
        {
          name: 'Dewey',
          email: 'dewey@junior-woodchucks.example.com',
          phones: ['4321'],
        }
      ]}

      template = [
        "People:",
        "<ul>",
        "  {{#each people as |person| }}",
        "  <li>",
        "    <ul>",
        "      <li>Name: {{person.name}}</li>",
        "      <li>Phones: {{#each person.phones as |phone|}} {{phone}} {{/each}}</li>",
        "      <li>email: {{person.email}}</li>",
        "    </ul>",
        "  </li>",
        "  {{else}}",
        "  <li>No one to display</li>",
        "  {{/each}}",
        "</ul>"
      ].join("\n")

      expect(evaluate(template, data)).to eq([
        "People:",
        "<ul>",
        "  ",
        "  <li>",
        "    <ul>",
        "      <li>Name: Huey</li>",
        "      <li>Phones:  1234  5678 </li>",
        "      <li>email: huey@junior-woodchucks.example.com</li>",
        "    </ul>",
        "  </li>",
        "  ",
        "  <li>",
        "    <ul>",
        "      <li>Name: Dewey</li>",
        "      <li>Phones:  4321 </li>",
        "      <li>email: dewey@junior-woodchucks.example.com</li>",
        "    </ul>",
        "  </li>",
        "  ",
        "</ul>"
      ].join("\n"))
    end
  end
end
