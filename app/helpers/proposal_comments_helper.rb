module ProposalCommentsHelper
  RANK_EMOJI = { up: '👍', nil_rank: '😐', down: '👎' }.freeze

  def link_to_rankup(proposal, proposal_comment)
    link_to_rank(rankup_proposal_proposal_comment_path(proposal, proposal_comment),
                 proposal_comment.id,
                 :up,
                 t('pages.proposals.show.voteup'))
  end

  def link_to_ranknil(proposal, proposal_comment)
    link_to_rank(ranknil_proposal_proposal_comment_path(proposal, proposal_comment),
                 proposal_comment.id,
                 :nil_rank,
                 t('pages.proposals.show.votenil'))
  end

  def link_to_rankdown(proposal, proposal_comment)
    link_to_rank(rankdown_proposal_proposal_comment_path(proposal, proposal_comment),
                 proposal_comment.id,
                 :down,
                 t('pages.proposals.show.votedown'))
  end

  def rank_emoji(type, full: false)
    emoji = RANK_EMOJI[type]
    css = "text-xl inline-block transition-transform hover:scale-125"
    css += " opacity-50" unless full
    tag.span(emoji, class: css)
  end

  def link_to_rank(url, comment_id, type, title)
    link_to rank_emoji(type),
            url,
            data: { turbo_method: :put, id: comment_id },
            class: "vote_comment",
            title: title
  end
end
