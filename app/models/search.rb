class Search < ApplicationRecord
  attr_accessor :groups, :proposals, :user_id, :blogs

  def find
    user = User.find(user_id)
    ability = Ability.new user

    self.groups = Group.search(q, true).accessible_by(ability).limit(5)

    self.proposals = Proposal.search(q).accessible_by(ability, :index, false).
                     select('proposals.*', "#{PgSearch::Configuration.alias('proposals')}.rank").limit(5)

    self.blogs = Blog.search(q, true).limit(5)
  end
end
