require 'rails_helper'

RSpec.describe Frm::Topic do
  describe 'moderation state predicates' do
    it 'reflects the persisted state column' do
      topic = described_class.new(state: 'approved')

      expect(topic).to be_approved
      expect(topic).not_to be_pending_review

      topic.state = 'pending_review'
      expect(topic).to be_pending_review
      expect(topic).not_to be_approved
    end
  end

  context 'when created' do
    let(:topic) { create(:frm_topic) }

    before do
      load_database
    end

    it 'has a slug' do
      expect(topic.slug).to eq to_slug_format(topic.subject)
    end

    context 'when subject changes' do
      let(:new_name) { Faker::Company.name }

      before do
        topic.update(subject: new_name)
      end

      it 'updates the slug' do
        expect(topic.slug).to eq to_slug_format(new_name)
      end
    end
  end
end
