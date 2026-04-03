module User::Proposable
  extend ActiveSupport::Concern

  included do
    has_many :proposal_presentations, inverse_of: :user, dependent: :destroy # TODO: replace with anonymous user
    has_many :proposals, through: :proposal_presentations, class_name: 'Proposal', inverse_of: :users
    has_many :user_votes, class_name: 'UserVote', inverse_of: :user
    has_many :proposal_comments, class_name: 'ProposalComment', inverse_of: :user
    has_many :partecipating_proposals, through: :proposal_comments, class_name: 'Proposal', source: :proposal
    has_many :proposal_comment_rankings, class_name: 'ProposalCommentRanking'
    has_many :proposal_rankings, class_name: 'ProposalRanking'
    has_many :proposal_revisions, inverse_of: :user
    has_many :proposal_nicknames, dependent: :destroy

    scope :non_blocking_notification, lambda { |notification_type|
      where.not(id: joins(:blocked_alerts).where(blocked_alerts: { notification_type_id: notification_type }).select(:id))
    }
  end

  def last_proposal_comment
    proposal_comments.order('created_at desc').first
  end

  def is_my_proposal?(proposal_id)
    proposals.exists?(id: proposal_id)
  end

  def has_ranked_proposal?(proposal_id)
    proposal_rankings.exists?(proposal_id: proposal_id)
  end

  def comment_rank(comment)
    ranking = proposal_comment_rankings.find_by(proposal_comment_id: comment.id)
    ranking.try(:ranking_type_id)
  end

  def can_rank_again_comment?(comment)
    ranking = proposal_comment_rankings.find_by(proposal_comment_id: comment.id)
    return true unless ranking
    return true if ranking.updated_at < comment.updated_at

    last_suggest = comment.replies.order('created_at desc').first
    return false unless last_suggest

    ranking.updated_at < last_suggest.created_at
  end
end
