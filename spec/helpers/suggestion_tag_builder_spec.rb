require 'rails_helper'

RSpec.describe SuggestionTagBuilder, type: :helper do
  let(:object_name) { 'proposal' }
  let(:template) { ActionView::Base.empty }
  let(:builder) { SuggestionTagBuilder.new(object_name, nil, template, {}) }

  describe '#suggestion_tag' do
    it 'returns a string' do
      result = builder.suggestion_tag(:title)
      expect(result).to be_a(String)
    end
  end

  describe '#field_name' do
    it 'returns the field name without index' do
      result = builder.field_name('title')
      expect(result).to eq('proposal[title]')
    end

    it 'returns the field name with index' do
      result = builder.field_name('title', 0)
      expect(result).to eq('proposal[0][title]')
    end
  end

  describe '#field_id' do
    it 'returns the field id without index' do
      result = builder.field_id('title')
      expect(result).to eq('proposal_title')
    end

    it 'returns the field id with index' do
      result = builder.field_id('title', 1)
      expect(result).to eq('proposal_1_title')
    end
  end
end
