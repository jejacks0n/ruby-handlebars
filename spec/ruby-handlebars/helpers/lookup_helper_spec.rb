# {{#with (lookup additional_evidence.disputer_evidence.dispute_rebuttal 0)}}
#   {{#if this.has_attachment}}
#     <div>
#       Fig 9. Policy Disclosure
#     </div>
#   {{/if}}
# {{/with}}

require 'spec_helper'
require_relative './shared'

describe Handlebars::Helpers::LookupHelper do
  let(:subject) { described_class }
  let(:hbs) { Handlebars::Handlebars.new }

  it_behaves_like "a registerable helper", "lookup"

  context '.apply' do
    include_context "shared apply helper"
  end

  context "integration" do
    include_context "shared helpers integration tests"

    let(:data) do
      {
        people: ["Nils", "Yehuda"],
        cities: [
          "Darmstadt",
          "San Francisco",
        ],
      }
    end

    it "can lookup details" do
      expect(evaluate(<<~TEMPLATE, data).strip).to eq("Nils lives in Darmstadt\nYehuda lives in San Francisco")
        {{#each people}}
          {{~this}} lives in {{lookup ../cities @index}}
        {{/each}}
      TEMPLATE
    end

  end
  #
  #   it "changes the evaluation context" do
  #     template = <<~HANDLEBARS
  #       {{#with person}}
  #       {{firstname}} {{lastname}}
  #       {{/with}}
  #     HANDLEBARS
  #
  #     expect(evaluate(template, person_data).strip).to eq("Yehuda Katz")
  #   end
  #
  #   it "supports block parameters" do
  #     template = <<~HANDLEBARS
  #       {{#with city as | city |}}
  #         {{#with city.location as | loc |}}
  #           {{city.name}}: {{loc.north}} {{loc.east}}
  #         {{/with}}
  #       {{/with}}
  #     HANDLEBARS
  #
  #     expect(evaluate(template, city_data).strip).to eq("San Francisco: 37.73, -122.44")
  #   end
  #
  #   it "supports else blocks" do
  #     template = <<~HANDLEBARS
  #       {{#with city}}
  #       {{city.name}} (not shown because there is no city)
  #       {{else}}
  #       No city found
  #       {{/with}}
  #     HANDLEBARS
  #
  #     expect(evaluate(template, person_data).strip).to eq("No city found")
  #   end
  #
  #   it "supports simple relative paths" do
  #     template = <<~HANDLEBARS
  #       {{#with city}}
  #         {{#with location}}
  #           {{../name}}: {{../population}} -- {{north}}
  #         {{/with}}
  #       {{/with}}
  #     HANDLEBARS
  #
  #     expect(evaluate(template, city_data).strip).to eq("San Francisco: 883305 -- 37.73,")
  #   end
  #
  #   it "supports complex relative paths", skip: "Relative paths are not yet supported" do
  #     template = <<~HANDLEBARS
  #       {{#with city as | city |}}
  #         {{#with city.location as | loc |}}
  #           {{city.name}}: {{../population}}
  #         {{/with}}
  #       {{/with}}
  #     HANDLEBARS
  #
  #     expect(evaluate(template, city_data).strip).to eq("San Francisco: 883305")
  #   end
  #
  #   context "white space" do
  #     it "can be stripped in simple cases" do
  #       result = evaluate("[ {{~#with city}}  {{city.name}}  {{/with~}} ]", city_data)
  #       expect(result).to eq("[  San Francisco  ]")
  #
  #       result = evaluate("[ {{~#with city}}  {{~city.name~}}  {{/with~}} ]", city_data)
  #       expect(result).to eq("[San Francisco]")
  #
  #       result = evaluate("[ {{~#with city~}}  {{city.name}}  {{~/with~}} ]", city_data)
  #       expect(result).to eq("[San Francisco]")
  #     end
  #
  #     it "can be stripped in complex cases with else" do
  #       result = evaluate("[ {{~#with city~}}  {{city.name}}  {{else}}  otherwise  {{/with~}} ]", city_data)
  #       expect(result).to eq("[San Francisco  ]")
  #
  #       result = evaluate("[ {{~#with city~}}  {{city.name}}  {{~else}}  otherwise  {{/with~}} ]", city_data)
  #       expect(result).to eq("[San Francisco]")
  #
  #       result = evaluate("[ {{~#with city~}}  {{city.name}}  {{else}}  otherwise  {{/with~}} ]", person_data)
  #       expect(result).to eq("[  otherwise  ]")
  #
  #       result = evaluate("[ {{~#with city~}}  {{city.name}}  {{else~}}  otherwise  {{~/with~}} ]", person_data)
  #       expect(result).to eq("[otherwise]")
  #     end
  #   end
  # end
end
