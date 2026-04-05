require 'rails_helper'

RSpec.describe User::Profileable, type: :model, seeds: true do
  let!(:user) { create(:user) }

  describe '#fullname' do
    it 'combines name and surname' do
      user.name = 'Mario'
      user.surname = 'Rossi'
      expect(user.fullname).to eq 'Mario Rossi'
    end
  end

  describe '#to_s' do
    it 'returns fullname' do
      expect(user.to_s).to eq user.fullname
    end
  end

  describe '#to_param' do
    it 'returns id with slugified fullname' do
      param = user.to_param
      expect(param).to start_with(user.id.to_s)
      expect(param).to match(/^\d+-.+/)
    end
  end

  describe '#user_image_url' do
    it 'returns a gravatar URL when no avatar is attached and email is present' do
      expect(user.avatar.attached?).to be false
      expect(user.email).to be_present
      url = user.user_image_url
      expect(url).to include('gravatar.com')
    end

    it 'returns empty string when no avatar and no email' do
      user.email = nil
      url = user.user_image_url
      expect(url).to eq ''
    end
  end
end
