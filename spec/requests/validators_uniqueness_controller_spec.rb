require 'rails_helper'
require 'requests_helper'

RSpec.describe Validators::UniquenessController, seeds: true do
  describe 'GET group' do
    it 'returns valid: true for a unique group name' do
      get '/validators/uniqueness/group/', params: { group: { name: 'Definitely Unique Name 99999' } }
      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      expect(json['valid']).to be true
    end

    it 'returns valid: false for an existing group name' do
      user = create(:user)
      group = create(:group, current_user_id: user.id)
      get '/validators/uniqueness/group/', params: { group: { name: group.name } }
      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      expect(json['valid']).to be false
    end

    it 'returns valid: true when checking the same group id' do
      user = create(:user)
      group = create(:group, current_user_id: user.id)
      get '/validators/uniqueness/group/', params: { group: { name: group.name, id: group.id } }
      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      expect(json['valid']).to be true
    end
  end

  describe 'GET user' do
    it 'returns valid: true for a unique email' do
      get '/validators/uniqueness/user/', params: { user: { email: 'unique_99999@example.com' } }
      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      expect(json['valid']).to be true
    end

    it 'returns valid: false for an existing email' do
      user = create(:user)
      get '/validators/uniqueness/user/', params: { user: { email: user.email } }
      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      expect(json['valid']).to be false
    end
  end

  describe 'GET proposal' do
    it 'returns valid: true for a unique proposal title' do
      get '/validators/uniqueness/proposal/', params: { proposal: { title: 'Unique Proposal Title 99999' } }
      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      expect(json['valid']).to be true
    end

    it 'returns valid: false for an existing proposal title' do
      user = create(:user)
      proposal = create(:public_proposal, current_user_id: user.id)
      get '/validators/uniqueness/proposal/', params: { proposal: { title: proposal.title } }
      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      expect(json['valid']).to be false
    end
  end
end
