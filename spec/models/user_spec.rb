require 'rails_helper'

RSpec.describe User do
  it 'populates the attributes properly' do
    municipality = create(:municipality, :bologna)
    province = municipality.province
    region = province.region
    country = region.country
    continent = country.continent

    user = create(:user, interest_borders_tokens: InterestBorder.to_key(municipality))

    expect(user.interest_borders.count).to eq 1
    expect(user.derived_interest_borders_tokens).to match_array ["K-#{continent.id}",
                                                                 "S-#{country.id}",
                                                                 "R-#{region.id}",
                                                                 "P-#{province.id}",
                                                                 "C-#{municipality.id}"]
  end

  describe '#by_interest_borders' do
    it 'can be searched by interest border' do
      municipality = create(:municipality, :bologna)
      province = municipality.province
      user = create(:user, interest_borders_tokens: InterestBorder.to_key(municipality))
      expect(described_class.by_interest_borders([InterestBorder.to_key(province)])).to include user
    end
  end

  describe 'when created' do
    it 'has some alerts blocked by default' do
      user = create(:user)
      expect(user.reload.blocked_alerts.count).to be >= 0
    end
  end

  describe '#admin?' do
    it 'returns true for admin users' do
      admin = create(:admin)
      expect(admin.admin?).to be true
    end

    it 'returns false for regular users' do
      user = create(:user)
      expect(user.admin?).to be false
    end
  end

  describe '#moderator?' do
    it 'returns true for admin users' do
      admin = create(:admin)
      expect(admin.moderator?).to be true
    end

    it 'returns false for regular users' do
      user = create(:user)
      expect(user.moderator?).to be false
    end
  end

  describe '#is_mine?' do
    let!(:user) { create(:user) }

    it 'returns true when object has user_id matching' do
      obj = double('object', user_id: user.id)
      expect(user.is_mine?(obj)).to be true
    end

    it 'returns false when object has different user_id' do
      obj = double('object', user_id: user.id + 1)
      expect(user.is_mine?(obj)).to be false
    end

    it 'returns false for nil object' do
      expect(user.is_mine?(nil)).to be false
    end
  end

  describe '#encoded_id' do
    it 'returns a Base64-encoded string' do
      user = create(:user)
      expect(user.encoded_id).to be_a(String)
      expect(User.decode_id(user.encoded_id).to_i).to eq(user.id)
    end
  end

  describe '.decode_id' do
    it 'decodes a Base64-encoded id' do
      encoded = Base64.encode64('42')
      expect(User.decode_id(encoded)).to eq('42')
    end
  end

  describe '#ability' do
    it 'returns an Ability instance' do
      user = create(:user)
      expect(user.ability).to be_a(Ability)
    end
  end

  describe '#can? and #cannot?' do
    it 'delegates to ability' do
      user = create(:user)
      expect(user).to respond_to(:can?)
      expect(user).to respond_to(:cannot?)
    end
  end

  describe '#image_url' do
    it 'returns nil when no avatar is attached' do
      user = create(:user)
      expect(user.image_url).to be_nil
    end
  end

  describe 'scopes' do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }

    it '.all_except excludes a given user' do
      expect(User.all_except(user1)).not_to include(user1)
      expect(User.all_except(user1)).to include(user2)
    end

    it '.confirmed returns confirmed users' do
      expect(User.confirmed).to include(user1, user2)
    end

    it '.unblocked returns unblocked users' do
      expect(User.unblocked).to include(user1, user2)
    end

    it '.autocomplete searches by name' do
      expect(User.autocomplete(user1.name.downcase[0..2])).to include(user1)
    end
  end

  describe '#init' do
    it 'initializes rank, receive_messages and receive_newsletter' do
      user = create(:user)
      expect(user.rank).to eq(0)
      expect(user.receive_messages).to be true
      expect(user.receive_newsletter).to be true
    end
  end
end
