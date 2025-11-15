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
end
