module Admin
  class ManagerController < ::ApplicationController
    before_action :moderator_required
  end
end
