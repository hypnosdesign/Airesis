FactoryBot.define do
  factory :meeting_participation do
    association :user
    association :meeting
    response { 'Y' }
    guests { 0 }
    comment { '' }
  end
end
