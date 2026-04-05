require 'rails_helper'

RSpec.describe StepsHelper, type: :helper, seeds: true do
  let!(:user) { create(:user) }

  describe '#check_show_condition' do
    let(:step) { instance_double(Step, fragment: nil) }

    it 'returns step when fragment is nil (default case)' do
      result = helper.check_show_condition(step, user)
      expect(result).to eq step
    end

    it 'returns step when fragment is users_show and id matches user' do
      allow(step).to receive(:fragment).and_return('users_show')
      allow(helper).to receive(:params).and_return({ id: user.id.to_s })
      result = helper.check_show_condition(step, user)
      expect(result).to eq step
    end

    it 'returns nil when fragment is users_show and id does not match' do
      allow(step).to receive(:fragment).and_return('users_show')
      allow(helper).to receive(:params).and_return({ id: (user.id + 1).to_s })
      result = helper.check_show_condition(step, user)
      expect(result).to be_nil
    end
  end

  describe '#welcome_steps' do
    let(:step) { instance_double(Step, index: 0, tutorial_id: 1) }

    it 'returns false for step index 0 when user has few sign_ins' do
      user.update!(sign_in_count: 2)
      allow(step).to receive(:index).and_return(0)
      result = helper.welcome_steps(step, user)
      expect(result).to be false
    end

    it 'returns true for step index 0 when user has many sign_ins' do
      user.update!(sign_in_count: 10)
      allow(step).to receive(:index).and_return(0)
      result = helper.welcome_steps(step, user)
      expect(result).to be true
    end

    it 'returns false for step index 1 when user has no interest borders' do
      allow(step).to receive(:index).and_return(1)
      result = helper.welcome_steps(step, user)
      expect(result).to be false
    end

    it 'returns false for step index 2 when user has no group participations' do
      allow(step).to receive(:index).and_return(2)
      result = helper.welcome_steps(step, user)
      expect(result).to be false
    end

    it 'returns false for step index 3 when user has no proposals' do
      allow(step).to receive(:index).and_return(3)
      result = helper.welcome_steps(step, user)
      expect(result).to be false
    end

    it 'returns false for unknown step index' do
      allow(step).to receive(:index).and_return(99)
      result = helper.welcome_steps(step, user)
      expect(result).to be false
    end
  end

  describe '#show_proposal_steps' do
    let(:step) { instance_double(Step, index: 0) }

    it 'returns false for step index 0' do
      allow(step).to receive(:index).and_return(0)
      result = helper.show_proposal_steps(step, user)
      expect(result).to be false
    end

    it 'returns false for step index 1' do
      allow(step).to receive(:index).and_return(1)
      result = helper.show_proposal_steps(step, user)
      expect(result).to be false
    end
  end

  describe '#welcome_steps with truthy conditions' do
    let(:step) { instance_double(Step, index: 0, tutorial_id: 1) }

    it 'returns true for step index 1 when user has interest borders' do
      allow(user).to receive_message_chain(:interest_borders, :count).and_return(1)
      allow(step).to receive(:index).and_return(1)
      result = helper.welcome_steps(step, user)
      expect(result).to be true
    end

    it 'returns true for step index 2 when user has group participations' do
      create(:group, current_user_id: user.id)
      allow(step).to receive(:index).and_return(2)
      result = helper.welcome_steps(step, user)
      expect(result).to be true
    end

    it 'returns true for step index 3 when user has proposals' do
      create(:public_proposal, current_user_id: user.id)
      allow(step).to receive(:index).and_return(3)
      result = helper.welcome_steps(step, user)
      expect(result).to be true
    end
  end

  describe '#get_next_step' do
    it 'returns nil when user has no tutorial assignees matching the controller/action' do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:params).and_return({ controller: 'home', action: 'index' })
      result = helper.get_next_step(user)
      expect(result).to be_nil
    end
  end

  describe '#check_tutorial_status' do
    let!(:tutorial) { Tutorial.create!(name: 'Test Tutorial', controller: 'home', action: 'index') }
    let!(:step) { Step.create!(tutorial: tutorial, index: 0, title: 'Step 1', content: 'Do this', required: false) }
    let!(:assignee) { TutorialAssignee.create!(tutorial: tutorial, user: user, completed: false) }

    after do
      assignee.destroy
      step.destroy
      tutorial.destroy
    end

    it 'returns the next uncompleted step' do
      # check_step_condition returns false for step with no progress → next_step = step
      allow(helper).to receive(:check_step_condition).and_return(false)
      result = helper.check_tutorial_status(assignee)
      expect(result).to eq step
    end

    it 'marks tutorial as completed when all steps are done' do
      allow(helper).to receive(:check_step_condition).and_return(true)
      helper.check_tutorial_status(assignee)
      expect(assignee.reload.completed).to be true
    end
  end

  describe '#check_step_condition' do
    let!(:welcome_tutorial) { Tutorial.find_by(name: 'Welcome Tutorial') }

    context 'when TutorialProgress does not exist (no progress record)' do
      it 'returns false (rescue returns false when progress status raises)' do
        step = welcome_tutorial&.steps&.first
        skip 'Welcome Tutorial or steps not seeded' unless step

        result = helper.check_step_condition(step, user)
        expect(result).to be false
      end
    end

    context 'when progress status is DONE' do
      it 'returns true (step already done)' do
        step = welcome_tutorial&.steps&.first
        skip 'Welcome Tutorial or steps not seeded' unless step

        progress = TutorialProgress.create!(step: step, user: user, status: TutorialProgress::DONE)
        result = helper.check_step_condition(step, user)
        expect(result).to be true
      ensure
        progress&.destroy
      end
    end

    context 'when progress status is TODO' do
      it 'calls welcome_steps for Welcome Tutorial steps' do
        step = welcome_tutorial&.steps&.first
        skip 'Welcome Tutorial or steps not seeded' unless step

        progress = TutorialProgress.create!(step: step, user: user, status: TutorialProgress::TODO)
        # welcome_steps returns false since user has not signed in enough times
        result = helper.check_step_condition(step, user)
        expect(result).to be false
      ensure
        progress&.destroy
      end
    end
  end
end
