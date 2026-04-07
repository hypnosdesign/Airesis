# Un commento a una proposta, nella doppia veste di **contribute** (top-level) o **risposta** (reply).
#
# La distinzione è determinata da `parent_proposal_comment_id`:
# - `nil` → contribute (contributo principale nel dibattito)
# - presente → reply (risposta annidata sotto un contribute)
#
# Un contribute può essere **integrato** nella proposta (il suo testo viene incluso in una revisione)
# oppure marcato come **rumoroso** o **spam** dagli altri partecipanti tramite segnalazioni.
# I contatori `grave_reports_count` (spam) e `soft_reports_count` (rumore) si incrementano automaticamente.
#
# Il broadcast Turbo (`broadcast_remove_to`) rimuove il commento in real-time per tutti i client
# quando viene distrutto.
class ProposalComment < ApplicationRecord
  include ActionView::Helpers::TextHelper
  include Turbo::Broadcastable

  # Traccia solo le modifiche al `content` — la storia degli altri campi non è necessaria.
  has_paper_trail versions: { class_name: 'ProposalCommentVersion' }, only: [:content], on: %i[update destroy]

  # Rimozione real-time dal DOM via Turbo Streams quando il commento è distrutto.
  after_destroy_commit -> { broadcast_remove_to proposal, target: "comment_#{id}" }

  # == Associations

  belongs_to :user, class_name: 'User', inverse_of: :proposal_comments, foreign_key: :user_id
  # `contribute` è il parent; nil per i contributi top-level (senza parent).
  belongs_to :contribute, class_name: 'ProposalComment', inverse_of: :replies, foreign_key: :parent_proposal_comment_id, optional: true
  has_many :replies, class_name: 'ProposalComment', inverse_of: :contribute, foreign_key: :parent_proposal_comment_id, dependent: :destroy
  has_many :repliers, -> { distinct }, class_name: 'User', through: :replies, inverse_of: :proposal_comments, source: :user
  # `counter_cache: true` mantiene aggiornato `proposals.proposal_comments_count` ad ogni create/destroy.
  belongs_to :proposal, class_name: 'Proposal', foreign_key: :proposal_id, counter_cache: true, inverse_of: :proposal_comments
  has_many :rankings, class_name: 'ProposalCommentRanking', dependent: :destroy, inverse_of: :proposal_comment
  has_many :rankers, through: :rankings, class_name: 'User', source: :user
  # `paragraph` collega il commento a un paragrafo specifico del testo (commento contestuale/inline).
  belongs_to :paragraph, optional: true, inverse_of: :proposal_comments

  has_one :integrated_contribute, class_name: 'IntegratedContribute', inverse_of: :proposal_comment, dependent: :destroy
  has_many :proposal_revisions, class_name: 'ProposalRevision', through: :integrated_contributes

  has_many :reports, class_name: 'ProposalCommentReport', foreign_key: :proposal_comment_id

  # == Validations

  validates :content, length: { minimum: 10, maximum: CONTRIBUTE_MAX_LENGTH }

  attr_accessor :collapsed, :nickname_generated

  # == Callbacks

  after_initialize :set_collapsed

  validate :check_last_comment

  # == Scopes

  # Contributi top-level (senza parent): il dibattito principale della proposta.
  scope :contributes, -> { where(parent_proposal_comment_id: nil) }
  # Risposte (con parent): thread di discussione annidati sotto ogni contributo.
  scope :comments, -> { where.not(parent_proposal_comment_id: nil) }

  scope :unintegrated, -> { where(integrated: false) }
  # Contributi già integrati nel testo della proposta tramite una revisione.
  scope :integrated, -> { where(integrated: true) }

  scope :noise, -> { where(noise: true) }

  # Commenti visibili nel dibattito: né integrati né marcati come rumore.
  scope :listable, -> { where(integrated: false, noise: false) }

  # Commenti non ancora letti dall'utente: quelli su cui non ha ancora dato un ranking.
  # La subquery è necessaria perché `unread` è l'assenza di un ranking, non un campo diretto.
  scope :unread, lambda { |user_id, proposal_id|
    where('proposal_comments.id not in (select p2.id
                                        from proposal_comments p2
                                        join proposal_comment_rankings pr on p2.id = pr.proposal_comment_id
                                        where pr.user_id = ? and p2.proposal_id = ?)',
          user_id, proposal_id)
  }

  scope :removable, -> { noisy.where(noise: false) }

  # Contributi segnalati come spam da almeno CONTRIBUTE_MARKS utenti (soglia configurabile in config).
  scope :spam, -> { where('grave_reports_count >= ?', CONTRIBUTE_MARKS) }

  # Contributi segnalati come rumorosi (off-topic, ripetitivi) da almeno CONTRIBUTE_MARKS utenti.
  scope :noisy, -> { where('soft_reports_count >= ?', CONTRIBUTE_MARKS) }

  # `section_id` è usato dal form per sapere a quale sezione collegare il commento inline.
  attr_accessor :section_id

  before_create :set_paragraph_id

  after_create :generate_nickname

  # Solo i contributi top-level aggiornano `proposal_contributes_count` (non le risposte).
  after_create :increment_contributes_counter_cache, if: :is_contribute?
  after_destroy :decrement_contributes_counter_cache, if: :is_contribute?

  after_commit :send_email, on: :create
  after_commit :send_update_notifications, on: :update

  # == Instance Methods

  # @return [Boolean] true se è un contributo top-level (non è una risposta)
  def is_contribute?
    parent_proposal_comment_id.nil?
  end

  # @return [Boolean] true se è una risposta a un contributo
  def is_reply?
    parent_proposal_comment_id.present?
  end

  # Collega il commento al paragrafo corrispondente alla sezione scelta nel form.
  # Usa `where(...).first` perché ogni sezione ha esattamente un paragrafo principale.
  def set_paragraph_id
    self.paragraph = Paragraph.where(section_id: section_id).first
  end

  # I commenti partono collassati (false = espanso) — la view decide se mostrarli.
  def set_collapsed
    @collapsed = false
  end

  # Previene spam: almeno 30 secondi tra un commento e il successivo dello stesso utente.
  # Il controllo è abilitato solo se `LIMIT_COMMENTS` è true (configurabile per test/dev).
  def check_last_comment
    comments = proposal.proposal_comments.where(user_id: user_id).order('created_at DESC')
    comment = comments.first
    errors.add(:created_at, "devono passare almeno trenta secondi tra un commento e l'altro.") if LIMIT_COMMENTS && comment && ((Time.zone.now - comment.created_at) < 30.seconds)
  end

  # Raccoglie i dati della request HTTP per il rilevamento spam tramite Akismet.
  # Chiamato dal controller prima della validazione: `comment.request = request`.
  #
  # @param request [ActionDispatch::Request]
  def request=(request)
    self.user_ip = request.remote_ip
    self.user_agent = request.env['HTTP_USER_AGENT']
    self.referrer = truncate(request.env['HTTP_REFERER'], length: 255)
  end

  # Tutti i partecipanti a questo thread: chi ha risposto + l'autore del contributo originale.
  #
  # @return [Array<User>]
  def participants
    repliers | [user]
  end

  # @return [Boolean] true se il commento è collegato a un paragrafo specifico
  def has_location?
    !paragraph.nil?
  end

  # Posizione testuale del commento nel documento: "Titolo sezione" o "Soluzione > Titolo sezione".
  # Usato per mostrare il contesto del commento inline nella vista di dibattito.
  #
  # @return [String, nil] percorso testuale o nil se senza localizzazione
  def location
    ret = nil
    if paragraph
      section = paragraph.section
      ret = section.title.to_s
      ret = "#{section.solution.title_with_seq} > #{ret}" if section.solution
    end
    ret
  end

  # @return [void]
  def send_email
    NotificationProposalCommentCreate.perform_later(id)
  end

  # Invia notifica di aggiornamento solo se il contenuto è effettivamente cambiato.
  # `previous_changes` è disponibile solo nel callback `after_commit`.
  #
  # @return [void]
  def send_update_notifications
    NotificationProposalCommentUpdate.perform_later(id) if previous_changes.include?(:content) && previous_changes[:content].first != previous_changes[:content].last
  end

  # Genera (o recupera) il nickname anonimo dell'utente per questa proposta.
  # L'accessor `nickname_generated` permette alla view di sapere se è stato appena creato.
  #
  # @return [void]
  def generate_nickname
    proposal_nickname = ProposalNickname.generate(user, proposal)
    self.nickname_generated = proposal_nickname.generated
  end

  # Rimuove l'integrazione del commento: cancella il record `IntegratedContribute`
  # e ripristina il flag `integrated: false` per permettere una nuova integrazione.
  #
  # @return [void]
  def unintegrate
    integrated_contribute.destroy
    update(integrated: false)
  end

  private

  def decrement_contributes_counter_cache
    add_to_contributes_counter(-1)
  end

  def increment_contributes_counter_cache
    add_to_contributes_counter(1)
  end

  # Usa `update_columns` per aggiornare il counter senza passare per le validazioni e i callback.
  # Il counter viene gestito manualmente perché il counter_cache di Rails conta tutti i commenti,
  # mentre `proposal_contributes_count` conta solo i contributi top-level.
  def add_to_contributes_counter(num)
    proposal.update_columns(proposal_contributes_count: proposal.proposal_contributes_count + num)
  end
end
