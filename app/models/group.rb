# Un gruppo è la comunità di base di Airesis: raccoglie utenti, proposte, eventi, forum e blog.
#
# I gruppi possono essere pubblici o privati (`private = true`).
# Ogni gruppo ha almeno un portavoce (ruolo admin), un quorum di default e un forum.
#
# La membership è gestita tramite `GroupParticipation` con `ParticipationRole` configurabile.
# Le richieste di adesione seguono la policy definita da `accept_requests`:
#   - {REQ_BY_PORTAVOCE} — approvate dal portavoce
#   - {REQ_BY_VOTE} — approvate per voto
#   - {REQ_BY_BOTH} — approvate da entrambi
class Group < ApplicationRecord
  extend FriendlyId
  include Taggable
  include PgSearch::Model

  pg_search_scope :search, lambda { |query, any_word = false|
    { query: query,
      against: { name: 'A' },
      order_within_rank: 'group_participations_count desc, created_at desc',
      using: { tsearch: { any_word: any_word } } }
  }

  friendly_id :name, use: %i[slugged history]

  has_paper_trail versions: { class_name: 'GroupVersion' }
  has_rich_text :description
  has_rich_text :rule_book

  include ImageHelper

  # == Constants

  # Valori per il campo `accept_requests`: definisce chi approva le richieste di adesione.
  REQ_BY_PORTAVOCE = 'p'.freeze
  REQ_BY_VOTE = 'v'.freeze
  REQ_BY_BOTH = 'b'.freeze

  # Valori per il campo `status`: usati da `CalculateGroupStatistics` worker.
  STATUS_ACTIVE = 'active'.freeze
  STATUS_FEW_USERS_A = 'few_users_a'.freeze

  # == Validations

  validates :name, presence: true, uniqueness: true, length: { within: 3..60 }

  validates :description, presence: true
  validates :facebook_page_url, length: { within: 10..255, allow_blank: true }
  validates :title_bar, length: { within: 1..255, allow_blank: true }
  validates :interest_border_id, presence: true
  validates :default_role_name, presence: { on: :create }

  attr_reader :participant_tokens
  attr_accessor :default_role_name, :default_role_actions, :current_user_id

  # == Associations

  has_many :group_follows, class_name: 'GroupFollow', dependent: :destroy
  has_many :post_publishings, class_name: 'PostPublishing', inverse_of: :group, dependent: :destroy

  has_many :group_participations, class_name: 'GroupParticipation', dependent: :destroy
  has_many :participants, through: :group_participations, source: :user, class_name: 'User'
  # I "portavoce" sono gli utenti con ruolo admin del gruppo — hanno tutti i permessi di moderazione.
  has_many :portavoce, -> { where(['group_participations.participation_role_id = ?', ParticipationRole.admin.id]) }, through: :group_participations, source: :user, class_name: 'User'

  has_many :followers, through: :group_follows, source: :user, class_name: 'User'
  has_many :blog_posts, through: :post_publishings, source: :blog_post
  has_many :participation_requests, class_name: 'GroupParticipationRequest', dependent: :destroy
  has_many :requesting, through: :participation_requests, source: :user, class_name: 'User'

  has_many :participation_roles, -> { order 'participation_roles.id DESC' }, class_name: 'ParticipationRole', dependent: :destroy
  belongs_to :interest_border, class_name: 'InterestBorder', foreign_key: :interest_border_id
  belongs_to :default_participation_role, class_name: 'ParticipationRole', foreign_key: :participation_role_id, optional: true
  has_many :meeting_organizations, class_name: 'MeetingOrganization', foreign_key: 'group_id', dependent: :destroy

  has_many :events, through: :meeting_organizations, class_name: 'Event', source: :event
  has_many :next_events, -> { where(['endtime > ?', Time.zone.now]) }, through: :meeting_organizations, class_name: 'Event', source: :event

  has_many :proposal_supports, class_name: 'ProposalSupport', dependent: :destroy
  has_many :supported_proposals, through: :proposal_supports, class_name: 'Proposal'

  has_many :group_proposals, class_name: 'GroupProposal', dependent: :destroy
  has_many :proposals, through: :group_proposals, class_name: 'Proposal', source: :proposal

  has_many :group_quorums, class_name: 'GroupQuorum', dependent: :destroy
  has_many :quorums, -> { order 'seq nulls last, quorums.id' }, through: :group_quorums, class_name: 'BestQuorum', source: :quorum

  has_many :voters, -> { include(:participation_roles).where(['participation_roles.id = ?', ParticipationRole.admin.id]) }, through: :group_participations, source: :user, class_name: 'User'

  has_many :group_areas, dependent: :destroy

  has_many :search_participants

  has_many :group_tags, dependent: :destroy
  has_many :tags, through: :group_tags, class_name: 'Tag'

  # invitations
  has_many :group_invitations
  has_many :group_invitation_emails, through: :group_invitations

  # forum
  has_many :forums, class_name: 'Frm::Forum', foreign_key: 'group_id', dependent: :destroy
  has_many :topics, through: :forums, class_name: 'Frm::Topic', source: :topics

  has_many :last_topics, through: :forums, class_name: 'Frm::Topic', source: :topics

  has_many :categories, class_name: 'Frm::Category', foreign_key: 'group_id', dependent: :destroy
  has_many :mods, class_name: 'Frm::Mod', foreign_key: 'group_id', dependent: :destroy

  has_one :statistic, class_name: 'GroupStatistic'

  has_one_attached :image

  validates :image, size: { less_than: UPLOAD_LIMIT_IMAGES.bytes },
                    content_type: ['image/jpeg', 'image/png', 'image/gif']


  # == Scopes

  # Filtra gruppi per territorio usando l'array PostgreSQL `derived_interest_borders_tokens`.
  # Usa l'operatore `@>` (contains) per trovare gruppi il cui territorio include `ib` o suoi antenati.
  scope :by_interest_border, ->(ib) { where('derived_interest_borders_tokens @> ARRAY[?]::varchar[]', ib) }

  # == Callbacks

  before_create :pre_populate
  after_create :after_populate

  # Crea la directory privata per elfinder (file manager) dopo ogni commit, non solo al create.
  # L'after_commit garantisce che la directory esista anche se il record è già presente in DB.
  after_commit :create_folder

  before_save :normalize_blank_values

  def normalize_blank_values
    [:admin_title].each do |att|
      self[att] = nil if self[att].blank?
    end
  end

  # == Instance Methods

  # Inizializza il gruppo prima della creazione:
  # - aggiunge il creatore come portavoce (admin)
  # - copia tutti i quorum pubblici visibili come quorum privati del gruppo
  # - crea il ruolo di partecipazione di default con i permessi specificati dall'utente
  #
  # I quorum vengono duplicati (non condivisi) per permettere al gruppo di modificarli indipendentemente.
  def pre_populate
    # Il creatore diventa automaticamente portavoce e il suo ingresso è pre-approvato (status_id = 3)
    participation_requests.build(user_id: current_user_id, group_participation_request_status_id: 3)
    group_participations.build(user_id: current_user_id, participation_role: ParticipationRole.admin)

    BestQuorum.visible.each do |quorum|
      copy = quorum.dup
      copy.public = false # i quorum del gruppo sono sempre privati
      copy.save!
      group_quorums.build(quorum_id: copy.id)
    end

    active_actions = default_role_actions.index_with { |_a| true }
    participation_role = participation_roles.build(active_actions.merge(name: default_role_name,
                                                                        description: I18n.t('pages.groups.edit_permissions.default_role')))
    participation_role.save!
    self.default_participation_role = participation_role
    self.max_storage_size = UPLOAD_LIMIT_GROUPS / 1024
  end

  # Post-create: assegna il group_id al ruolo di default e crea i forum iniziali.
  # L'`after_create` è necessario perché in `pre_populate` (before_create) il gruppo non ha ancora un ID.
  # Crea sempre un forum privato (solo partecipanti) e uno pubblico (visibile fuori dal gruppo).
  def after_populate
    # Il group_id non era disponibile nel before_create, va impostato qui
    default_participation_role.update_attribute(:group_id, id)

    # Forum privato: discussioni interne riservate ai partecipanti
    private = categories.create(name: I18n.t('frm.admin.categories.default_private'), visible_outside: false)
    private_f = private.forums.build(name: I18n.t('frm.admin.forums.default_private'), description: I18n.t('frm.admin.forums.default_private_description'), visible_outside: false)
    private_f.group = self
    private_f.save!

    # Forum pubblico: discussioni visibili anche agli utenti non iscritti al gruppo
    public = categories.create(name: I18n.t('frm.admin.categories.default_public'))
    public_f = public.forums.create(name: I18n.t('frm.admin.forums.default_public'), description: I18n.t('frm.admin.forums.default_public_description'))
    public_f.group = self
    public_f.save!

    GroupStatistic.create(group_id: id, valutations: 0, vote_valutations: 0, good_score: 0).save!
  end

  def destroy
    update_attribute(:participation_role_id, ParticipationRole.admin.id) && super
  end

  # return true if the group is private and do not show anything to non-participants
  def is_private?
    private
  end

  # Utenti del gruppo che hanno il permesso per una specifica azione.
  # Le azioni sono colonne boolean in `participation_roles` (es. `participate_proposals`, `vote_proposals`).
  # Usato per calcolare le `valutations` del quorum e il conteggio degli elettori eleggibili.
  #
  # @param action [Symbol, String] nome della colonna in `participation_roles` (es. `:vote_proposals`)
  # @return [ActiveRecord::Relation<User>]
  def scoped_participants(action)
    participants.
      joins('JOIN participation_roles on group_participations.participation_role_id = participation_roles.id').
      where("participation_roles.#{action} = true").
      distinct
  end

  def participant_tokens=(ids)
    self.participant_ids = ids.split(',')
  end

  def interest_border_tkn
    interest_border_token
  end

  # Imposta il confine di interesse dal token UI nel formato 'X-id' (es. 'C-123' = comune 123).
  # Ricostruisce `derived_interest_borders_tokens` risalendo la gerarchia geografica.
  # Il token viene memorizzato sia come stringa (`interest_border_token`) sia come FK (`interest_border_id`).
  def interest_border_tkn=(tkn)
    if tkn.present?
      ftype = tkn[0, 1] # tipo di territorio: primo carattere del token (C=comune, P=provincia, N=nazione...)
      fid = tkn[2..] # ID del territorio: tutto ciò che segue il separatore '-'
      found = InterestBorder.table_element(tkn)
      if found # se ho trovato qualcosa, allora l'identificativo è corretto e posso procedere alla creazione del confine di interesse
        self.interest_border_token = tkn
        interest_b = InterestBorder.find_or_create_by(territory_type: InterestBorder::I_TYPE_MAP[ftype], territory_id: fid)
        self.interest_border = interest_b

        derived_row = found
        while derived_row
          self.derived_interest_borders_tokens |= [InterestBorder.to_key(derived_row)]
          derived_row = derived_row.parent
        end
      end
    end
  end

  def request_by_vote?
    accept_requests == REQ_BY_VOTE
  end

  def request_by_portavoce?
    accept_requests == REQ_BY_PORTAVOCE
  end

  def request_by_both?
    accept_requests == REQ_BY_BOTH
  end

  # Ricerca gruppi con supporto per tag, full-text (pg_search) e filtro territoriale.
  # Se `params[:and]` è false usa la modalità `any_word` (OR tra i termini).
  # Se `params[:area]` è presente filtra per territorio derivato, altrimenti per token esatto.
  #
  # @param params [Hash] parametri di ricerca: :search, :tag, :interest_border, :area, :and
  # @return [ActiveRecord::Relation<Group>]
  def self.look(params)
    query = params[:search]
    params[:and] = params[:and].nil? || params[:and]
    tag = params[:tag]

    if tag
      joins(:tags).where(tags: { text: tag }).order('group_participations_count desc, created_at desc')
    else
      groups = if query.blank?
                 Group.order(group_participations_count: :desc, created_at: :desc)
               else
                 search(query, !params[:and])
               end
      if params[:interest_border]
        groups = if params[:area]
                   groups.by_interest_border(params[:interest_border])
                 else
                   groups.where(interest_border_token: params[:interest_border])
                 end
      end
      groups
    end
  end

  # Gruppi più attivi per numero di partecipanti, opzionalmente filtrati per territorio.
  # Usato per le widget di homepage e portlet territoriali.
  #
  # @param territory [InterestBorder, nil] se presente, filtra per territorio derivato
  # @param limit [Integer] numero massimo di risultati (default: 5)
  # @return [ActiveRecord::Relation<Group>]
  def self.most_active(territory = nil, limit: 5)
    groups = Group.includes(interest_border: :territory)
    groups = groups.by_interest_border(InterestBorder.to_key(territory)) if territory.present?
    groups.order(group_participations_count: :desc).limit(limit)
  end

  def should_generate_new_friendly_id?
    name_changed?
  end

  # ActionText setter override: build the association if not yet initialized
  # (needed because the `description` DB column shadows ActionText's lazy builder
  # when the record is new and AR column methods are generated after has_rich_text)
  def description=(value)
    (rich_text_description || build_rich_text_description).body = value
  end

  def rule_book=(value)
    (rich_text_rule_book || build_rich_text_rule_book).body = value
  end

  private

  def self.autocomplete(term)
    where('lower(groups.name) LIKE :term', term: "%#{term.downcase}%").
      limit(10).
      select('groups.name, groups.id, groups.image_id, groups.image_url, groups.image_file_name').
      order('groups.name asc')
  end

  def create_folder
    dir = "#{Rails.root}/private/elfinder/#{id}"
    FileUtils.mkdir_p dir # it automatically create "private" folder and doesn't error if the directory is already present
  end
end
