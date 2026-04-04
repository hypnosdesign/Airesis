require 'rails_helper'

RSpec.describe Taggable, seeds: true do
  # Use Proposal as the host model for Taggable
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id, tags_list: 'ruby,rails,testing') }

  describe '#tags_list' do
    it 'returns a comma-separated list of tag texts' do
      result = proposal.tags_list
      expect(result).to be_a(String)
      expect(result).to include('ruby')
      expect(result).to include('rails')
    end
  end

  describe '#tags_list_json' do
    it 'returns a comma-separated list of tag texts' do
      result = proposal.tags_list_json
      expect(result).to be_a(String)
    end
  end

  describe '#tags_data' do
    it 'returns JSON with tag id and name' do
      result = proposal.tags_data
      parsed = JSON.parse(result)
      expect(parsed).to be_an(Array)
      expect(parsed.first).to have_key('id')
      expect(parsed.first).to have_key('name')
    end
  end

  describe '#tags_with_links' do
    it 'returns HTML links for each tag' do
      result = proposal.tags_with_links
      expect(result).to include('<a href="/tags/')
      expect(result).to include('ruby')
    end
  end

  describe '#save_tags' do
    it 'creates tags from the tags_list string' do
      new_proposal = create(:public_proposal, current_user_id: user.id, tags_list: 'newtag1,newtag2')
      expect(new_proposal.tags.map(&:text)).to include('newtag1', 'newtag2')
    end

    it 'reuses existing tags' do
      tag = Tag.find_or_create_by(text: 'existingtag')
      new_proposal = create(:public_proposal, current_user_id: user.id, tags_list: 'existingtag')
      expect(new_proposal.tags).to include(tag)
    end
  end
end
