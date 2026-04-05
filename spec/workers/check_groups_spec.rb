require 'rails_helper'

RSpec.describe CheckGroups, type: :worker, seeds: true do
  let!(:worker) { described_class.new }

  it 'runs without error when no groups need checking' do
    expect { worker.perform }.not_to raise_error
  end

  it 'processes old groups with few participants' do
    user = create(:user)
    group = create(:group, current_user_id: user.id)
    group.update_columns(created_at: 10.days.ago, status: 'active')
    expect { worker.perform }.not_to raise_error
  end
end
