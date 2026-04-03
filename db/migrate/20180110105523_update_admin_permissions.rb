class UpdateAdminPermissions < ActiveRecord::Migration[5.2]
  def change
    ParticipationRole.find_by(name: ParticipationRole::ADMINISTRATOR, group_id: nil).update(Hash[GroupAction::LIST.map { |a| [a, true] }])
  end
end
