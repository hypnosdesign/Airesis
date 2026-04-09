class SearchesController < ApplicationController
  include UsersHelper

  def index
    @search = Search.new
    @search.q = params[:term]
    @search.user_id = current_user.id
    @search.find
    results = []
    groups = @search.groups.to_a
    if groups.any?
      group_ids = groups.map(&:id)
      proposals_count_by_group = GroupProposal.where(group_id: group_ids).group(:group_id).count
      results << { value: t('controllers.searches.index.groups_divider'), type: 'Divider' }
      groups.each do |group|
        results << { value: group.name, type: 'Group', url: group_url(group), proposals_url: group_proposals_url(group), events_url: group_events_url(group), participants_num: group.group_participations_count, proposals_num: proposals_count_by_group[group.id] || 0, image: group.image.attached? ? url_for(group.image) : nil }
      end
    end
    proposals = @search.proposals.includes(:groups).to_a
    if proposals.any?
      results << { value: 'Proposals', type: 'Divider' }
      proposals.each do |proposal|
        url = proposal.private? ?
          group_proposal_url(proposal.groups.first, proposal) : proposal_url(proposal)
        results << { value: proposal.title, type: 'Proposal', url: url, image: '/img/gruppo-anonimo.png' }
      end
    end
    blogs = @search.blogs.includes(:user).to_a
    if blogs.any?
      results << { value: 'Blogs', type: 'Divider' }
      blogs.each do |blog|
        results << { value: blog.title, type: 'Blog', url: blog_url(blog), username: blog.user.fullname, user_url: user_url(blog.user), image: avatar(blog.user, size: 40) }
      end
    end
    render json: results
  end
end
