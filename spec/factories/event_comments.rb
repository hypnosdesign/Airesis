FactoryBot.define do
  factory :event_comment do
    association :user
    association :event, factory: :meeting_event
    body { 'Practical event information.' }
  end
end
