require 'spec_helper'
require_relative './shared'

describe Handlebars::Helpers::UnlessHelper do
  let(:subject) { Handlebars::Helpers::UnlessHelper }
  let(:hbs) { Handlebars::Handlebars.new }
  let(:ctx) { Handlebars::Context.new(hbs, {}) }

  it_behaves_like "a registerable helper", "unless"

  context '.apply' do
    it_behaves_like "a helper running the main block", "false", false
    it_behaves_like "a helper running the main block", "an empty string", ""
    it_behaves_like "a helper running the main block", "an empty list", []
    it_behaves_like "a helper running the main block", "an empty hash", {}

    it_behaves_like "a helper running the else block", 'true', true
    it_behaves_like "a helper running the else block", 'a non-empty string', 'something'
    it_behaves_like "a helper running the else block", 'a non-empty list', ['a']
    it_behaves_like "a helper running the else block", 'a non-empty hash', {a: 'b'}

    context 'when else_block is not present' do
      include_context "shared apply helper"
      let(:params) { true }
      let(:else_block) { nil }

      it 'returns an empty-string' do
        expect(subject.apply(ctx, params, hash: {}, block: block, else_block: else_block, collapse: {})).to eq("")

        expect(block).not_to have_received(:fn)
        expect(else_block).not_to have_received(:fn)
      end
    end
  end

  context 'integration' do
    include_context "shared helpers integration tests"

    it 'without else' do
      template = [
        "{{#unless condition}}",
        "  Show something",
        "{{/unless}}"
      ].join("\n")
      expect(evaluate(template, {condition: false})).to eq("\n  Show something\n")
      expect(evaluate(template, {condition: true})).to eq("")
    end

    it 'with an else' do
      template = [
        "{{#unless condition}}",
        "  Show something",
        "{{ else }}",
        "  Do not show something",
        "{{/unless}}"
      ].join("\n")
      expect(evaluate(template, {condition: false})).to eq("\n  Show something\n")
      expect(evaluate(template, {condition: true})).to eq("\n  Do not show something\n")
    end


    context "white space" do
      it "can be stripped in simple cases" do
        result = evaluate("foo {{#unless false}}  bar  {{/unless}} baz")
        expect(result).to eq("foo   bar   baz")

        result = evaluate("foo {{~#unless false}}  bar  {{/unless~}} baz")
        expect(result).to eq("foo  bar  baz")

        result = evaluate("foo {{~#unless false~}}  bar  {{~/unless~}} baz")
        expect(result).to eq("foobarbaz")
      end

      it "can be stripped in complex cases with else" do
        result = evaluate("foo {{#unless foo}}  bar  {{else}}  baz  {{/unless}} qux", foo: false)
        expect(result).to eq("foo   bar   qux")

        result = evaluate("foo {{~#unless foo}}  bar  {{else}}  baz  {{/unless~}} qux", foo: false)
        expect(result).to eq("foo  bar  qux")

        result = evaluate("foo {{~#unless foo~}}  bar  {{~else}}  baz  {{/unless~}} qux", foo: false)
        expect(result).to eq("foobarqux")

        result = evaluate("foo {{~#unless foo}}  bar  {{else}}  baz  {{/unless~}} qux", foo: true)
        expect(result).to eq("foo  baz  qux")

        result = evaluate("foo {{~#unless foo}}  bar  {{else~}}  baz  {{/unless~}} qux", foo: true)
        expect(result).to eq("foobaz  qux")

        result = evaluate("foo {{~#unless foo}}  bar  {{else~}}  baz  {{~/unless~}} qux", foo: true)
        expect(result).to eq("foobazqux")
      end
    end
  end
end
