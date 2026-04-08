class ProposalSchulzeVote < ApplicationRecord
  belongs_to :proposal, class_name: 'Proposal', foreign_key: :proposal_id, inverse_of: :schulze_votes

  def description
    solution_ids = proposal.solutions.pluck(:id)
    solution_titles = Solution.where(id: solution_ids).pluck(:id, :title).to_h
    desc = ''
    preferences.scan(/(;|,|)(\d+)/).map { |d, n| [d, n.to_i] }.each do |d, n|
      desc += (d == ',' ? ' , ' : ' <br/>') unless d.empty?
      desc += I18n.t("pages.proposals.edit.new_solution_title.#{proposal.proposal_type.name.downcase}",
                     num: solution_ids.index(n) + 1) + CGI.escapeHTML(solution_titles[n].to_s)
    end
    desc.html_safe
  end
end
