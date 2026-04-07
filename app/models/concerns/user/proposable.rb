# Gestisce la relazione dell'utente con le proposte: autoria, commenti, voti, ranking.
#
# Un utente può essere autore di una proposta (`proposal_presentations`) e/o partecipante
# (`partecipating_proposals` — proposte a cui ha commentato).
# I `proposal_nicknames` sono usati per l'anonimato durante il dibattito.
module User::Proposable
  extend ActiveSupport::Concern

  included do
    # TODO: sostituire con utente anonimo quando una proposta viene eliminata (invece di destroy)
    has_many :proposal_presentations, inverse_of: :user, dependent: :destroy
    has_many :proposals, through: :proposal_presentations, class_name: 'Proposal', inverse_of: :users
    has_many :user_votes, class_name: 'UserVote', inverse_of: :user
    has_many :proposal_comments, class_name: 'ProposalComment', inverse_of: :user
    # Proposte a cui l'utente ha partecipato come commentatore (non necessariamente autore).
    has_many :partecipating_proposals, through: :proposal_comments, class_name: 'Proposal', source: :proposal
    has_many :proposal_comment_rankings, class_name: 'ProposalCommentRanking'
    has_many :proposal_rankings, class_name: 'ProposalRanking'
    has_many :proposal_revisions, inverse_of: :user
    has_many :proposal_nicknames, dependent: :destroy

    # Utenti che non hanno bloccato un tipo di notifica specifico.
    # Usato da `NotificationSender` per filtrare i destinatari prima dell'invio.
    scope :non_blocking_notification, lambda { |notification_type|
      where.not(id: joins(:blocked_alerts).where(blocked_alerts: { notification_type_id: notification_type }).select(:id))
    }
  end

  # @return [ProposalComment, nil] l'ultimo commento dell'utente su qualsiasi proposta
  def last_proposal_comment
    proposal_comments.order('created_at desc').first
  end

  # @param proposal_id [Integer] ID della proposta
  # @return [Boolean] true se l'utente è tra gli autori della proposta
  def is_my_proposal?(proposal_id)
    proposals.exists?(id: proposal_id)
  end

  # @param proposal_id [Integer] ID della proposta
  # @return [Boolean] true se l'utente ha già dato un ranking alla proposta
  def has_ranked_proposal?(proposal_id)
    proposal_rankings.exists?(proposal_id: proposal_id)
  end

  # Tipo di ranking dato dall'utente a un commento specifico.
  #
  # @param comment [ProposalComment]
  # @return [Integer, nil] ranking_type_id (1=positivo, 2=neutro, 3=negativo) o nil se non rankato
  def comment_rank(comment)
    ranking = proposal_comment_rankings.find_by(proposal_comment_id: comment.id)
    ranking.try(:ranking_type_id)
  end

  # Determina se l'utente può cambiare il proprio ranking su un commento.
  # Si può ri-rankare se:
  # - Il commento è stato aggiornato dopo l'ultimo ranking dell'utente
  # - Oppure il commento ha ricevuto nuove repliche dopo l'ultimo ranking
  # Questo incentiva il re-engagement quando il dibattito evolve.
  #
  # @param comment [ProposalComment]
  # @return [Boolean]
  def can_rank_again_comment?(comment)
    ranking = proposal_comment_rankings.find_by(proposal_comment_id: comment.id)
    return true unless ranking                                  # mai rankato → può rankare
    return true if ranking.updated_at < comment.updated_at     # commento aggiornato dopo il ranking

    last_suggest = comment.replies.order('created_at desc').first
    return false unless last_suggest                            # nessuna risposta → non può ri-rankare

    ranking.updated_at < last_suggest.created_at               # nuova risposta dopo il ranking
  end
end
