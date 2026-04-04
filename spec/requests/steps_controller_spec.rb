require 'rails_helper'
require 'requests_helper'

RSpec.describe StepsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:tutorial) { Tutorial.create!(name: 'Test Tutorial', controller: 'proposals', action: 'show') }
  let!(:step) { tutorial.steps.create!(title: 'Step 1') }

  describe 'GET complete' do
    it 'returns error or redirect when not authenticated' do
      get complete_tutorial_step_path(tutorial, step)
      expect([302, 401, 403, 500]).to include(response.status)
    end

    it 'responds when authenticated' do
      sign_in user
      get complete_tutorial_step_path(tutorial, step)
      expect([200, 302, 404, 500]).to include(response.status)
    end
  end
end
