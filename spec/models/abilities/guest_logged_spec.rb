require 'rails_helper'
require 'requests_helper'
require 'cancan/matchers'

RSpec.describe 'Guest and Logged abilities', type: :model, seeds: true do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:group_owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: group_owner.id) }

  describe 'Guest ability' do
    let(:ability) { Ability.new(nil) }

    it 'can read public events' do
      create(:meeting_event, user: user, private: false) rescue nil
      expect(ability).to be_able_to(:read, Event.new(private: false))
    end

    it 'cannot read private events' do
      expect(ability).not_to be_able_to(:read, Event.new(private: true))
    end

    it 'can show users' do
      expect(ability).to be_able_to(:show, user)
    end

    it 'can read groups' do
      expect(ability).to be_able_to(:read, group)
    end

    it 'can index groups' do
      expect(ability).to be_able_to(:index, Group)
    end

    it 'can ask for participation in group' do
      expect(ability).to be_able_to(:ask_for_participation, group)
    end

    it 'can read public proposals' do
      proposal = create(:public_proposal, current_user_id: user.id)
      expect(ability).to be_able_to(:read, proposal)
    end

    it 'cannot read private proposals not visible outside' do
      proposal = create(:group_proposal, current_user_id: user.id,
                        groups: [group], visible_outside: false)
      expect(ability).not_to be_able_to(:read, proposal)
    end

    it 'can read published blog posts' do
      blog = create(:blog, user: user)
      blog_post = create(:blog_post, blog: blog, user: user, status: BlogPost::PUBLISHED)
      expect(ability).to be_able_to(:read, blog_post)
    end
  end

  describe 'Logged ability' do
    let(:ability) { Ability.new(user) }

    it 'can read their own alerts' do
      expect(ability).to be_able_to(:read, Alert.new(user_id: user.id))
    end

    it 'cannot read other users alerts' do
      expect(ability).not_to be_able_to(:read, Alert.new(user_id: other_user.id))
    end

    it 'can read public quorums' do
      expect(ability).to be_able_to(:read, BestQuorum.new(public: true))
    end

    it 'can send messages to other users with receive_messages enabled' do
      other = User.new(receive_messages: true, email: 'other@example.com')
      expect(ability).to be_able_to(:send_message, other)
    end

    it 'cannot send messages to users without receive_messages' do
      other = User.new(receive_messages: false, email: 'other@example.com')
      expect(ability).not_to be_able_to(:send_message, other)
    end

    it 'cannot send messages to themselves' do
      expect(ability).not_to be_able_to(:send_message, user)
    end

    it 'can read published blog posts' do
      blog = create(:blog, user: other_user)
      blog_post = create(:blog_post, blog: blog, user: other_user, status: BlogPost::PUBLISHED)
      expect(ability).to be_able_to(:read, blog_post)
    end

    it 'can destroy their own authentication if they have an email' do
      auth = Authentication.new(user: user)
      user.email = 'test@example.com'
      expect(ability).to be_able_to(:destroy, auth)
    end
  end
end
