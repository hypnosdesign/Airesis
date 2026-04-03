RSpec.configure do |config|
  config.before(:all) do
    load Rails.root.join('db/seeds/data/database_functions.rb')
  end

  config.before do
    # TODO: these should not be needed.
    # Use count checks to make seed loading idempotent (safe for rspec-retry within same transaction)
    load Rails.root.join('db/seeds/data/notification_types.rb') if NotificationType.count.zero?
    load Rails.root.join('db/seeds/data/proposal_types.rb') if ProposalType.count.zero?
    load Rails.root.join('db/seeds/data/proposal_states.rb') if ProposalState.count.zero?
    load Rails.root.join('db/seeds/data/event_types.rb') if EventType.count.zero?
    load Rails.root.join('db/seeds/data/participation_roles.rb') if ParticipationRole.where(group_id: nil).count.zero?
    load Rails.root.join('db/seeds/data/vote_types.rb') if VoteType.count.zero?
    load Rails.root.join('db/seeds/data/quorums.rb') if BestQuorum.count.zero?
    SysLocale.find_or_create_by!(key: 'en-EU') do |sl|
      sl.host = 'localhost'
      sl.territory = create(:continent, :europe)
      sl.default = true
    end
    %w[folksonomy recaptcha proposal_categories group_areas socialnetwork_active user_messages].each do |name|
      Configuration.find_or_create_by!(name: name) do |c|
        c.value = name == 'recaptcha' ? 0 : 1
      end
    end
  end

  config.before(:each, seeds: true) do
    load_database
  end

  # TODO: remove
  def load_municipalities
    create(:municipality, :bologna)
  end

  def load_database
    load_municipalities
    ParticipationRole.find_or_create_by!(name: ParticipationRole::ADMINISTRATOR, group_id: nil) do |role|
      GroupAction::LIST.each { |a| role[a] = true }
      role.description = 'Amministratore'
    end
    return unless BestQuorum.count == 0

    base_attrs = { percentage: nil, minutes_m: 0, hours_m: 0, good_score: 50, bad_score: 50, vote_percentage: 0,
                   vote_minutes: nil, vote_good_score: 50, t_percentage: 's', t_minutes: 's', t_good_score: 's',
                   t_vote_percentage: 's', t_vote_minutes: 'f', t_vote_good_score: 's', public: true }
    BestQuorum.create([base_attrs.merge(name: '1 giorno', days_m: 1, seq: 1),
                       base_attrs.merge(name: '3 giorni', days_m: 3, seq: 2),
                       base_attrs.merge(name: '7 giorni', days_m: 7, seq: 3),
                       base_attrs.merge(name: '15 giorni', days_m: 15, seq: 4),
                       base_attrs.merge(name: '30 giorni', days_m: 30, seq: 5)])
  end
end
