module Abilities
  class RailsAdmin
    include CanCan::Ability

    def initialize(user)
      return unless user.admin?

      can :access, :rails_admin
      can :read, :dashboard
      can :manage, :all
    end
  end
end
