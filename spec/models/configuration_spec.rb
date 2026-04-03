require 'rails_helper'

RSpec.describe Configuration, type: :model, seeds: true do
  describe '.config_active?' do
    it 'returns true when config value is non-zero' do
      Configuration.find_or_create_by!(name: 'folksonomy') { |c| c.value = 1 }
      expect(described_class.config_active?('folksonomy')).to be_truthy
    end

    it 'returns false when config value is zero' do
      Configuration.find_or_create_by!(name: 'recaptcha') { |c| c.value = 0 }
      expect(described_class.config_active?('recaptcha')).to be_falsey
    end

    it 'returns false when config does not exist' do
      expect(described_class.config_active?('nonexistent_config')).to be_falsey
    end
  end

  describe '.socialnetwork_active' do
    it 'returns the status of socialnetwork_active config' do
      Configuration.find_or_create_by!(name: 'socialnetwork_active') { |c| c.value = 1 }
      Configuration.instance_variable_set(:@socialnetwork_active, nil)
      expect(described_class.socialnetwork_active).to be_truthy
    end
  end

  describe '.user_messages' do
    it 'returns the status of user_messages config' do
      Configuration.find_or_create_by!(name: 'user_messages') { |c| c.value = 1 }
      Configuration.instance_variable_set(:@user_messages, nil)
      expect(described_class.user_messages).to be_truthy
    end
  end

  describe '.folksonomy' do
    it 'returns the status of folksonomy config' do
      Configuration.find_or_create_by!(name: 'folksonomy') { |c| c.value = 1 }
      Configuration.instance_variable_set(:@folksonomy, nil)
      expect(described_class.folksonomy).to be_truthy
    end
  end

  describe '.recaptcha' do
    it 'returns false when recaptcha is disabled' do
      Configuration.find_or_create_by!(name: 'recaptcha') { |c| c.value = 0 }
      Configuration.instance_variable_set(:@recaptcha, nil)
      expect(described_class.recaptcha).to be_falsey
    end
  end

  describe '.group_areas' do
    it 'returns the status of group_areas config' do
      Configuration.find_or_create_by!(name: 'group_areas') { |c| c.value = 1 }
      Configuration.instance_variable_set(:@group_areas, nil)
      expect(described_class.group_areas).to be_truthy
    end
  end

  describe '.proposal_categories' do
    it 'returns the status of proposal_categories config' do
      Configuration.find_or_create_by!(name: 'proposal_categories') { |c| c.value = 1 }
      Configuration.instance_variable_set(:@proposal_categories, nil)
      expect(described_class.proposal_categories).to be_truthy
    end
  end
end
