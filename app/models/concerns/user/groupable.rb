# Gestisce la partecipazione dell'utente ai gruppi e alle aree di lavoro.
#
# Un utente può avere ruoli diversi in gruppi diversi tramite `ParticipationRole`.
# I "portavoce" sono gli utenti con ruolo 'amministratore' — hanno tutti i permessi nel gruppo.
# Le aree di lavoro (`GroupArea`) sono sottoinsiemi di un gruppo con permessi indipendenti.
module User::Groupable
  extend ActiveSupport::Concern

  included do
    has_many :group_participations, dependent: :destroy, inverse_of: :user
    has_many :groups, through: :group_participations, class_name: 'Group'
    # Gruppi in cui l'utente è portavoce (ruolo 'amministratore').
    has_many :portavoce_groups, -> { joins(' INNER JOIN participation_roles ON participation_roles.id = group_participations.participation_role_id').where("(participation_roles.name = 'amministratore')") }, through: :group_participations, class_name: 'Group', source: 'group'

    has_many :area_participations, class_name: 'AreaParticipation', inverse_of: :user
    has_many :group_areas, through: :area_participations, class_name: 'GroupArea'

    has_many :participation_roles, through: :group_participations, class_name: 'ParticipationRole', inverse_of: :user
    has_many :group_follows, class_name: 'GroupFollow', inverse_of: :user
    has_many :followed_groups, through: :group_follows, class_name: 'Group', source: :group
    has_many :group_participation_requests, dependent: :destroy
  end

  # Gruppi suggeriti basati sul primo confine di interesse dell'utente.
  # Limita a 12 risultati per le widget di homepage.
  #
  # @return [ActiveRecord::Relation<Group>]
  def suggested_groups
    border = interest_borders.first
    params = {}
    params[:interest_border_obj] = border
    params[:limit] = 12
    Group.look(params)
  end

  # Partecipazioni a gruppi dove l'utente ha un'abilitazione specifica O è portavoce.
  # I portavoce (amministratori) sono sempre inclusi indipendentemente dal permesso richiesto.
  #
  # @param abilitation [String] colonna boolean in `participation_roles` (es. 'participate_proposals')
  # @return [ActiveRecord::Relation<GroupParticipation>]
  def scoped_group_participations(abilitation)
    group_participations.
      joins(' INNER JOIN participation_roles ON participation_roles.id = group_participations.participation_role_id').
      where("participation_roles.name = 'amministratore' OR participation_roles.#{abilitation} = true")
  end

  # Gruppi dove l'utente ha un'abilitazione specifica O è portavoce.
  # `excluded_groups` permette di escludere gruppi già selezionati in un form multi-step.
  #
  # @param abilitation [String] colonna boolean in `participation_roles`
  # @param excluded_groups [Array<Group>, nil] gruppi da escludere dal risultato
  # @return [Array<Group>]
  def scoped_groups(abilitation, excluded_groups = nil)
    ret = groups.
          joins(' INNER JOIN participation_roles ON participation_roles.id = group_participations.participation_role_id').
          where("(participation_roles.name = 'amministratore' OR participation_roles.#{abilitation} = true")
    excluded_groups ? ret - excluded_groups : ret
  end

  # Aree di lavoro accessibili dall'utente in un gruppo specifico.
  # I portavoce vedono tutte le aree; gli altri utenti vedono solo quelle
  # per cui hanno il permesso specificato da `abilitation_id`.
  # Se `abilitation_id` è nil restituisce tutte le aree a cui l'utente partecipa.
  #
  # @param group_id [Integer] ID del gruppo
  # @param abilitation_id [String, nil] colonna boolean in `area_roles` (es. 'insert_proposal')
  # @return [ActiveRecord::Relation<GroupArea>]
  def scoped_areas(group_id, abilitation_id = nil)
    group = Group.find(group_id)
    if group.portavoce.include? self
      group.group_areas # i portavoce vedono tutto
    elsif abilitation_id
      group_areas.joins(:area_roles).
        where(["group_areas.group_id = ? AND area_roles.#{abilitation_id} = true AND area_participations.area_role_id = area_roles.id", group_id]).
        distinct
    else
      group_areas.joins(:area_roles).
        where(['group_areas.group_id = ?', group_id]).distinct
    end
  end

  # Verifica se l'utente ha già inviato una richiesta di partecipazione al gruppo.
  # Usato nella view per mostrare "richiesta inviata" invece del bottone "unisciti".
  #
  # @param group_id [Integer] ID del gruppo
  # @return [GroupParticipationRequest, nil] la richiesta esistente o nil
  def has_asked_for_participation?(group_id)
    group_participation_requests.find_by(group_id: group_id)
  end
end
