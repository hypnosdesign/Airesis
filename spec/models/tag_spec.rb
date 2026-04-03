require 'rails_helper'

RSpec.describe Tag, type: :model, seeds: true do
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id, tags_list: 'ruby,rails,coding') }

  describe '#as_json' do
    it 'returns a hash with id and name as the tag text' do
      tag = Tag.find_by(text: 'ruby')
      result = tag.as_json
      expect(result).to eq({ id: 'ruby', name: 'ruby' })
    end
  end

  describe 'before_save :escape_text' do
    it 'strips whitespace from text' do
      tag = Tag.create(text: '  mytag  ')
      expect(tag.text).to eq 'mytag'
    end

    it 'converts text to lowercase' do
      tag = Tag.create(text: 'MyTag')
      expect(tag.text).to eq 'mytag'
    end

    it 'removes dots from text' do
      tag = Tag.create(text: 'my.tag')
      expect(tag.text).to eq 'mytag'
    end

    it 'removes apostrophes from text' do
      tag = Tag.create(text: "my'tag")
      expect(tag.text).to eq 'mytag'
    end

    it 'removes slashes from text' do
      tag = Tag.create(text: 'my/tag')
      expect(tag.text).to eq 'mytag'
    end
  end

  describe '#nearest' do
    it 'returns an array of tags' do
      tag = Tag.find_by(text: 'ruby')
      result = tag.nearest
      expect(result).to be_an(Array)
    end

    it 'does not include the tag itself' do
      tag = Tag.find_by(text: 'ruby')
      result = tag.nearest
      expect(result.map(&:text)).not_to include('ruby')
    end

    it 'includes other tags from shared proposals' do
      tag = Tag.find_by(text: 'ruby')
      result = tag.nearest
      texts = result.map(&:text)
      expect(texts).to include('rails').or include('coding')
    end
  end

  describe '.for_twitter' do
    it 'returns tags formatted for Twitter' do
      Tag.where(text: %w[ruby rails coding]).each do |t|
        # already created via proposal
      end
      result = Tag.where(text: %w[ruby rails]).for_twitter
      expect(result).to include('#ruby')
      expect(result).to include('#rails')
    end
  end
end
