require_relative '../../spec_helper'

require_relative '../../../lib/ruby-handlebars'
require_relative '../../../lib/ruby-handlebars/helpers/register_default_helpers'


describe Handlebars::Helpers do
  context '.register_default_helpers' do
    it 'registers the default helpers' do
      hbs = double(Handlebars::Handlebars)
      allow(hbs).to receive(:register_helper)

      Handlebars::Helpers.register_default_helpers(hbs)

      expect(hbs).to have_received(:register_helper)
        .once.with('if', as: false)
        .once.with('unless', as: false)
        .once.with('lookup', as: false)
        .once.with('each', as: false)
        .once.with('each', as: true)
        .once.with('helperMissing', as: true)
        .once.with('helperMissing', as: false)
        .once.with('with', as: false)
        .once.with('with', as: true)
    end
  end
end
