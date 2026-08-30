module ProposalCommentsHelper
  RANK_ICONS = { up: 'fa-thumbs-up', nil_rank: 'fa-circle-question', down: 'fa-thumbs-down' }.freeze

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

  def rank_icon(type, full: false, label: nil)
    css = "fa-solid #{RANK_ICONS.fetch(type)} text-lg"
    css += " opacity-50" unless full
    tag.span(class: 'inline-flex min-h-11 min-w-11 items-center justify-center', aria: (label ? { label: label } : { hidden: true })) do
      tag.i(class: css, aria: { hidden: true })
    end
  end

  def link_to_rank(url, comment_id, type, title)
    link_to rank_icon(type),
            url,
            data: { turbo_method: :put, id: comment_id },
            class: 'vote_comment inline-flex min-h-11 min-w-11 items-center justify-center focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2',
            title: title,
            aria: { label: title }
  end
end
