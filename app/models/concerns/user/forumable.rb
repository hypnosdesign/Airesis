# Gestisce i permessi dell'utente nel forum integrato (namespace `Frm`).
#
# Il forum usa un sistema di permessi basato sulla membership al gruppo:
# - Categorie/forum con `visible_outside = true` sono leggibili da tutti
# - Per scrivere (topic, post) è sempre richiesta la partecipazione al gruppo
# - I moderatori del forum (`Frm::Mod`) hanno permessi aggiuntivi di gestione
#
# La tracciatura delle letture usa `Frm::View` con timestamp: un topic è "non letto"
# se `last_post_at > frm_views.updated_at`.
module User::Forumable
  extend ActiveSupport::Concern

  included do
    has_many :viewed, class_name: 'Frm::View'
    has_many :viewed_topics, class_name: 'Frm::Topic', through: :viewed, source: :viewable, source_type: 'Frm::Topic'
    # Topic con post più recenti dell'ultima visita: mostrati come non letti.
    has_many :unread_topics, -> { where 'frm_views.updated_at < frm_topics.last_post_at' }, class_name: 'Frm::Topic', through: :viewed, source: :viewable, source_type: 'Frm::Topic'
    has_many :memberships, class_name: 'Frm::Membership', inverse_of: :member, foreign_key: :member_id
    has_many :frm_mods, through: :memberships, class_name: 'Frm::Mod', source: :mod
  end

  # @param category [Frm::Category]
  # @return [Boolean] true se la categoria è pubblica o l'utente è nel gruppo
  def can_read_forem_category?(category)
    category.visible_outside || (category.group.participants.include? self)
  end

  # @param forum [Frm::Forum]
  # @return [Boolean] true se il forum è pubblico o l'utente è nel gruppo
  def can_read_forem_forum?(forum)
    forum.visible_outside || (forum.group.participants.include? self)
  end

  # Creare topic richiede sempre la partecipazione al gruppo, anche per forum pubblici.
  #
  # @param forum [Frm::Forum]
  # @return [Boolean]
  def can_create_forem_topics?(forum)
    forum.group.participants.include? self
  end

  # @param topic [Frm::Topic]
  # @return [Boolean]
  def can_reply_to_forem_topic?(topic)
    topic.forum.group.participants.include? self
  end

  # @param forum [Frm::Forum]
  # @return [Boolean]
  def can_edit_forem_posts?(forum)
    forum.group.participants.include? self
  end

  # I topic nascosti sono visibili solo all'autore e ai moderatori/admin del gruppo.
  #
  # @param topic [Frm::Topic]
  # @return [Boolean]
  def can_read_forem_topic?(topic)
    !topic.hidden? || forem_admin?(topic.forum.group) || (topic.user == self)
  end

  # @param forum [Frm::Forum]
  # @return [Boolean] true se l'utente è moderatore del forum
  def can_moderate_forem_forum?(forum)
    forum.moderator?(self)
  end

  # Admin del forum = chi può aggiornare il gruppo (portavoce).
  # Usa CanCanCan per non duplicare la logica di autorizzazione.
  #
  # @param group [Group]
  # @return [Boolean]
  def forem_admin?(group)
    can? :update, group
  end
end
