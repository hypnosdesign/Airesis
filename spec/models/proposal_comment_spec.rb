require 'rails_helper'

RSpec.describe ProposalComment, type: :model, seeds: true do
  let(:user) { create(:user) }
  let(:proposal) { create(:public_proposal, current_user_id: user.id) }

  before do
    load_municipalities
    proposal
  end

  context 'contributes count' do
    context 'when a contribute is added' do
      let!(:contribute) { create(:proposal_comment, proposal: proposal) }

      before do
        proposal.reload
      end

      it 'increases the number of comments of the proposal' do
        expect(proposal.proposal_comments_count).to eq 1
      end

      it 'increases the number of contributes of the proposal' do
        expect(proposal.proposal_contributes_count).to eq 1
      end

      context 'when a comment is added' do
        let!(:comment) { create(:proposal_comment, contribute: contribute, proposal: proposal) }

        before do
          proposal.reload
        end

        it 'increases the number of comments of the proposal' do
          expect(proposal.proposal_comments_count).to eq 2
        end

        it 'does not increase the number of contributes of the proposal' do
          expect(proposal.proposal_contributes_count).to eq 1
        end
      end
    end
  end

  describe '#is_contribute?' do
    it 'returns true when parent_proposal_comment_id is nil' do
      comment = build(:proposal_comment, parent_proposal_comment_id: nil)
      expect(comment.is_contribute?).to be true
    end

    it 'returns false when parent_proposal_comment_id is present' do
      contribute = create(:proposal_comment, proposal: proposal)
      comment = build(:proposal_comment, parent_proposal_comment_id: contribute.id, proposal: proposal)
      expect(comment.is_contribute?).to be false
    end
  end

  describe '#has_location?' do
    it 'returns false when paragraph is nil' do
      comment = build(:proposal_comment)
      expect(comment.has_location?).to be false
    end
  end

  describe '#location' do
    it 'returns nil when paragraph is nil' do
      comment = build(:proposal_comment)
      expect(comment.location).to be_nil
    end
  end

  describe '#participants' do
    it 'returns the comment user plus repliers' do
      contribute = create(:proposal_comment, proposal: proposal, user: user)
      expect(contribute.participants).to include(user)
    end
  end

  describe '#request=' do
    it 'sets user tracking fields from request' do
      comment = ProposalComment.new
      request = double('request',
        remote_ip: '127.0.0.1',
        env: { 'HTTP_USER_AGENT' => 'Mozilla/5.0', 'HTTP_REFERER' => 'http://example.com' }
      )
      comment.request = request
      expect(comment.user_ip).to eq('127.0.0.1')
      expect(comment.user_agent).to eq('Mozilla/5.0')
    end
  end

  describe 'scopes' do
    let!(:contribute) { create(:proposal_comment, proposal: proposal, user: user) }
    let!(:reply) { create(:proposal_comment, contribute: contribute, proposal: proposal, user: user) }

    it '.contributes returns only top-level comments' do
      expect(ProposalComment.contributes).to include(contribute)
      expect(ProposalComment.contributes).not_to include(reply)
    end

    it '.comments returns only replies' do
      expect(ProposalComment.comments).to include(reply)
      expect(ProposalComment.comments).not_to include(contribute)
    end
  end
end
