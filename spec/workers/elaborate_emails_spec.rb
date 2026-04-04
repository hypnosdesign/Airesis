require 'rails_helper'

RSpec.describe ElaborateEmails, type: :worker, seeds: true do
  let!(:worker) { described_class.new }

  it 'runs without error when no emails exist' do
    expect { worker.perform }.not_to raise_error
  end

  it 'marks unread emails as read' do
    email = ReceivedEmail.create!(from: 'test@example.com', body: 'Hello', read: false, token: 'nonexistent_token_xyz')
    worker.perform
    expect(email.reload.read).to be true
  end

  it 'processes email for existing forum topic when user exists' do
    user = create(:user)
    group = create(:group, current_user_id: user.id)
    category = Frm::Category.create!(name: 'Test', group: group, visible_outside: true)
    forum = Frm::Forum.create!(name: 'Test', description: 'Test', group: group, category: category)
    topic = create(:frm_topic, forum: forum, user: user)

    email = ReceivedEmail.create!(
      from: user.email,
      body: 'Reply text',
      read: false,
      token: topic.token
    )
    expect { worker.perform }.not_to raise_error
    expect(email.reload.read).to be true
  end
end
