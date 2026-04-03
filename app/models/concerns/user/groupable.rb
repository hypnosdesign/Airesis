module User::Groupable
  extend ActiveSupport::Concern

  included do
    has_many :group_participations, dependent: :destroy, inverse_of: :user
    has_many :groups, through: :group_participations, class_name: 'Group'
    has_many :portavoce_groups, -> { joins(' INNER JOIN participation_roles ON participation_roles.id = group_participations.participation_role_id').where("(participation_roles.name = 'amministratore')") }, through: :group_participations, class_name: 'Group', source: 'group'

    has_many :area_participations, class_name: 'AreaParticipation', inverse_of: :user
    has_many :group_areas, through: :area_participations, class_name: 'GroupArea'

    has_many :participation_roles, through: :group_participations, class_name: 'ParticipationRole', inverse_of: :user
    has_many :group_follows, class_name: 'GroupFollow', inverse_of: :user
    has_many :followed_groups, through: :group_follows, class_name: 'Group', source: :group
    has_many :group_participation_requests, dependent: :destroy
  end

  def suggested_groups
    border = interest_borders.first
    params = {}
    params[:interest_border_obj] = border
    params[:limit] = 12
    Group.look(params)
  end

  def scoped_group_participations(abilitation)
    group_participations.
      joins(' INNER JOIN participation_roles ON participation_roles.id = group_participations.participation_role_id').
      where("participation_roles.name = 'amministratore' OR participation_roles.#{abilitation} = true")
  end

  def scoped_groups(abilitation, excluded_groups = nil)
    ret = groups.
          joins(' INNER JOIN participation_roles ON participation_roles.id = group_participations.participation_role_id').
          where("(participation_roles.name = 'amministratore' OR participation_roles.#{abilitation} = true")
    excluded_groups ? ret - excluded_groups : ret
  end

  def scoped_areas(group_id, abilitation_id = nil)
    group = Group.find(group_id)
    if group.portavoce.include? self
      group.group_areas
    elsif abilitation_id
      group_areas.joins(:area_roles).
        where(["group_areas.group_id = ? AND area_roles.#{abilitation_id} = true AND area_participations.area_role_id = area_roles.id", group_id]).
        distinct
    else
      group_areas.joins(:area_roles).
        where(['group_areas.group_id = ?', group_id]).distinct
    end
  end

  def has_asked_for_participation?(group_id)
    group_participation_requests.find_by(group_id: group_id)
  end
end
