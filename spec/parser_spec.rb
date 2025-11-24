require_relative 'spec_helper'
require_relative '../lib/ruby-handlebars/parser'

describe Handlebars::Parser do
  let(:parser) { Handlebars::Parser.new }
  let(:collapse_options) {
    {
      collapse_before: nil,
      collapse_after: nil,
    }
  }

  context 'recognizes' do
    it 'simple templates' do
      expect(parser.parse('Ho hi !')).to eq(
        block_items: [{template_content: 'Ho hi !'}]
      )
    end

    it 'simple replacements' do
      expect(parser.parse('{{plic}}')).to eq(
        block_items: [
          collapse_options.merge(replaced_unsafe_item: 'plic')
        ]
      )

      expect(parser.parse('{{ plic}}')).to eq(
        block_items: [
          collapse_options.merge(replaced_unsafe_item: 'plic')
        ]
      )

      expect(parser.parse('{{plic }}')).to eq(
        block_items: [
          collapse_options.merge(replaced_unsafe_item: 'plic')
        ]
      )

      expect(parser.parse('{{ plic }}')).to eq(
        block_items: [
          collapse_options.merge(replaced_unsafe_item: 'plic')
        ]
      )

      expect(parser.parse('{{~ plic ~}}')).to eq(
        block_items: [
          collapse_before: '~',
          replaced_unsafe_item: 'plic',
          collapse_after: '~',
        ]
      )
    end

    it 'special variables' do
      expect(parser.parse('{{@first}}')).to eq(
        block_items: [
          collapse_options.merge(replaced_unsafe_item: '@first')
        ]
      )
      expect(parser.parse('{{@last}}')).to eq(
        block_items: [
          collapse_options.merge(replaced_unsafe_item: '@last')
        ]
      )
      expect(parser.parse('{{@index}}')).to eq(
        block_items: [
          collapse_options.merge(replaced_unsafe_item: '@index')
        ]
      )
    end

    it 'safe strings' do
      expect(parser.parse('{{{plic}}}')).to eq(
        block_items: [
          collapse_options.merge(replaced_safe_item: 'plic')
        ]
      )

      expect(parser.parse('{{{ plic}}}')).to eq(
        block_items: [
          collapse_options.merge(replaced_safe_item: 'plic')
        ]
      )

      expect(parser.parse('{{{plic }}}')).to eq(
        block_items: [
          collapse_options.merge(replaced_safe_item: 'plic')
        ]
      )

      expect(parser.parse('{{{ plic }}}')).to eq(
        block_items: [
          collapse_options.merge(replaced_safe_item: 'plic')
        ]
      )
    end

    it 'comments' do
      expect(parser.parse('{{! this is a comment }}')).to eq(
        block_items: [
          collapse_options.merge(comment: 'this is a comment ')
        ]
      )
    end

    context 'helpers' do
      it 'simple' do
        expect(parser.parse('{{ capitalize plic }}')).to eq(
          block_items: [
            collapse_options.merge(
              unsafe_helper_name: 'capitalize',
              parameters: {parameter_name: 'plic'}
            )
          ]
        )
      end

      it 'with single-quoted string parameter' do
        expect(parser.parse("{{ capitalize 'hi'}}")).to eq(
          block_items: [
            collapse_options.merge(
              unsafe_helper_name: 'capitalize',
              parameters: {parameter_name: {str_content: 'hi'}},
            )
          ]
        )
      end

      it 'with single-quoted empty string parameter' do
        expect(parser.parse("{{ capitalize ''}}")).to eq(
          block_items: [
            collapse_options.merge(
              unsafe_helper_name: 'capitalize',
              parameters: {parameter_name: {str_content: ''}},
            )
          ]
        )
      end

      it 'with double-quoted string parameter' do
        expect(parser.parse('{{ capitalize "hi"}}')).to eq(
          block_items: [
            collapse_options.merge(
              unsafe_helper_name: 'capitalize',
              parameters: {parameter_name: {str_content: 'hi'}},
            )
          ]
        )
      end

      it 'with double-quoted empty string parameter' do
        expect(parser.parse('{{ capitalize ""}}')).to eq(
          block_items: [
            collapse_options.merge(
              unsafe_helper_name: 'capitalize',
              parameters: {parameter_name: {str_content: ''}},
            )
          ]
        )
      end

      it 'with multiple parameters' do
        expect(parser.parse('{{ concat plic ploc plouf }}')).to eq(
          block_items: [
            collapse_options.merge(
              unsafe_helper_name: 'concat',
              parameters: [
                {parameter_name: 'plic'},
                {parameter_name: 'ploc'},
                {parameter_name: 'plouf'}
              ]
            )
          ]
        )
      end

      it "with path derived parameters" do
        expect(parser.parse('{{ uppercase ../plic }}')).to eq(
          block_items: [
            collapse_options.merge(
              unsafe_helper_name: 'uppercase',
              parameters: {parameter_name: '../plic'},
            )
          ]
        )
      end

      it 'block' do
        expect(parser.parse('{{#capitalize}}plic{{/capitalize}}')).to eq(
          block_items: [
            collapse_options.merge(
              helper_name: 'capitalize',
              block_items: [{template_content: 'plic'}],
              close_options: collapse_options
            )
          ]
        )
      end

      it 'block with parameters' do
        expect(parser.parse('{{#comment "#"}}plic{{/comment}}')).to eq(
          block_items: [
            collapse_options.merge(
              helper_name: 'comment',
              parameters: {parameter_name: {str_content: '#'}},
              block_items: [{template_content: 'plic'}],
              close_options: collapse_options
            )
          ]
        )
      end

      it 'imbricated blocks' do
        expect(parser.parse('{{#comment "#"}}plic {{#capitalize}}ploc{{/capitalize}} plouc{{/comment}}')).to eq(
          block_items: [
            collapse_options.merge(
              helper_name: 'comment',
              parameters: {parameter_name: {str_content: '#'}},
              block_items: [
                {template_content: 'plic '},
                collapse_options.merge(
                  helper_name: 'capitalize',
                  block_items: [{template_content: 'ploc'}],
                  close_options: collapse_options
                ),
                {template_content: ' plouc'}
              ],
              close_options: collapse_options
            )
          ]
        )
      end

      it 'helpers as arguments' do
        expect(parser.parse('{{foo (bar baz)}}')).to eq(
          block_items: [
            collapse_options.merge(
              unsafe_helper_name: 'foo',
              parameters: {
                safe_helper_name: 'bar',
                parameters: {parameter_name: 'baz'}
              }
            )
          ]
        )
      end
    end

    context 'as helpers' do
      it 'recognizes the "as |...|" writing' do
        expect(parser.parse('{{#each items as |item|}}plic{{/each}}')).to eq(
          block_items: [
            collapse_options.merge(
              helper_name: 'each',
              parameters: {parameter_name: 'items'},
              as_parameters: {parameter_name: 'item'},
              block_items: [{template_content: 'plic'}],
              close_options: collapse_options
            )
          ]
        )
      end

      it 'supports the "else" statement' do
        expect(parser.parse('{{#each items as |item|}}plic{{else}}Hummm, empty{{/each}}')).to eq(
          block_items: [
            collapse_options.merge(
              helper_name: 'each',
              parameters: {parameter_name: 'items'},
              as_parameters: {parameter_name: 'item'},
              block_items: [{template_content: 'plic'}],
              else_block_items: [{template_content: 'Hummm, empty'}],
              else_options: collapse_options,
              close_options: collapse_options
            )
          ]
        )
      end

      it 'can be imbricated' do
        expect(parser.parse('{{#each items as |item|}}{{#each item as |char index|}}show item{{/each}}{{else}}Hummm, empty{{/each}}')).to eq(
          block_items: [
            collapse_options.merge(
              helper_name: 'each',
              parameters: {parameter_name: 'items'},
              as_parameters: {parameter_name: 'item'},
              block_items: [
                collapse_options.merge(
                  helper_name: 'each',
                  parameters: {parameter_name: 'item'},
                  as_parameters: [
                    {parameter_name: 'char'},
                    {parameter_name: 'index'}
                  ],
                  block_items: [{template_content: 'show item'}],
                  close_options: collapse_options
                )
              ],
              else_block_items: [{template_content: 'Hummm, empty'}],
              else_options: collapse_options,
              close_options: collapse_options
            )
          ]
        )
      end
    end

    context 'if block' do
      it 'simple' do
        expect(parser.parse('{{#if something}}show something else{{/if}}')).to eq(
          block_items: [
            collapse_options.merge(
              helper_name: 'if',
              parameters: {parameter_name: 'something'},
              block_items: [{template_content: 'show something else'}],
              close_options: collapse_options
            )
          ]
        )
      end

      it "handles whitespace collapsing" do
        expect(parser.parse('{{~#if foo~}}foo{{else~}}bar{{~/if}}')).to eq(
          block_items: [
            {
              helper_name: "if",
              parameters: {parameter_name: "foo"},
              collapse_before: "~",
              collapse_after: "~",
              block_items: [{template_content: "foo"}],
              else_block_items: [{template_content: "bar"}],
              else_options: {
                collapse_before: nil,
                collapse_after: "~"
              },
              close_options: {
                collapse_before: "~",
                collapse_after: nil
              }
            }
          ]
        )
      end

      it 'with an else statement' do
        expect(parser.parse('{{#if something}}ok{{else}}not ok{{/if}}')).to eq(
          block_items: [
            collapse_options.merge(
              helper_name: 'if',
              parameters: {parameter_name: 'something'},
              block_items: [{template_content: 'ok'}],
              else_block_items: [{template_content: 'not ok'}],
              else_options: collapse_options,
              close_options: collapse_options
            )
          ]
        )
      end

      it 'imbricated' do
        expect(parser.parse('{{#if something}}{{#if another_thing}}Plic{{/if}}ploc{{/if}}')).to eq(
          block_items: [
            collapse_options.merge(
              helper_name: 'if',
              parameters: {parameter_name: 'something'},
              block_items: [
                collapse_options.merge(
                  helper_name: 'if',
                  parameters: {parameter_name: 'another_thing'},
                  block_items: [{template_content: 'Plic'}],
                  close_options: collapse_options,
                ),
                {template_content: 'ploc'}
              ],
              close_options: collapse_options,
            )
          ]
        )
      end

      it 'imbricated block with elses' do
        expect(parser.parse('{{#if something}}{{#if another_thing}}Case 1{{else}}Case 2{{/if}}{{else}}{{#if another_thing}}Case 3{{else}}Case 4{{/if}}{{/if}}')).to eq(
          block_items: [
            collapse_options.merge(
              helper_name: "if",
              parameters: {parameter_name: "something"},
              block_items: [
                collapse_options.merge(
                  helper_name: "if",
                  parameters: {parameter_name: "another_thing"},
                  block_items: [{template_content: "Case 1"}],
                  else_block_items: [{template_content: "Case 2"}],
                  else_options: collapse_options,
                  close_options: collapse_options
                )
              ],
              else_block_items: [
                collapse_options.merge(
                  helper_name: "if",
                  parameters: {parameter_name: "another_thing"},
                  block_items: [{template_content: "Case 3"}],
                  else_block_items: [{template_content: "Case 4"}],
                  else_options: collapse_options,
                  close_options: collapse_options
                )
              ],
              else_options: collapse_options,
              close_options: collapse_options
            )
          ]
        )
      end
    end

    context 'each block' do
      it 'simple' do
        expect(parser.parse('{{#each people}} {{this.name}} {{/each}}')).to eq(
          block_items: [
            collapse_options.merge(
              helper_name: 'each',
              parameters: {parameter_name: 'people'},
              block_items: [
                {template_content: ' '},
                collapse_options.merge(replaced_unsafe_item: 'this.name'),
                {template_content: ' '}
              ],
              close_options: collapse_options
            )
          ]
        )
      end

      it 'imbricated' do
        expect(parser.parse('{{#each people}} {{this.name}} <ul> {{#each this.contact}} <li>{{this}}</li> {{/each}}</ul>{{/each}}')).to eq(
          block_items: [
            collapse_options.merge(
              helper_name: 'each',
              parameters: {parameter_name: 'people'},
              block_items: [
                {template_content: ' '},
                collapse_options.merge(replaced_unsafe_item: 'this.name'),
                {template_content: ' <ul> '},
                collapse_options.merge(
                  helper_name: 'each',
                  parameters: {parameter_name: 'this.contact'},
                  block_items: [
                    {template_content: ' <li>'},
                    collapse_options.merge(replaced_unsafe_item: 'this'),
                    {template_content: '</li> '}
                  ],
                  close_options: collapse_options
                ),
                {template_content: '</ul>'},
              ],
              close_options: collapse_options
            )
          ]
        )
      end
    end

    context 'templates with single curlies' do
      it 'works with loose curlies' do
        expect(parser.parse('} Hi { hey } {')).to eq(
          block_items: [
            {template_content: '} Hi { hey } {'}
          ]
        )
      end

      it 'works with groups of curlies' do
        expect(parser.parse('{ Hi }{ hey }')).to eq(
          block_items: [
            {template_content: '{ Hi }{ hey }'}
          ]
        )
      end

      it 'works with closing curly before value' do
        expect(parser.parse('Hi }{{ hey }}')).to eq(
          block_items: [
            {template_content: 'Hi }'},
            collapse_options.merge(replaced_unsafe_item: 'hey')
          ]
        )
      end

      it 'works with closing curly before value at the start' do
        expect(parser.parse('}{{ hey }}')).to eq(
          block_items: [
            {template_content: '}'},
            collapse_options.merge(replaced_unsafe_item: 'hey')
          ]
        )
      end
    end
  end
end
