require 'rails_helper'

RSpec.describe Event do
  let(:user) { create(:user) }
  let(:events) { create_list(:meeting_event, 3, user: user) }

  it 'can be built' do
    expect(create(:vote_event)).to be_valid
    expect(create(:meeting_event)).to be_valid
  end

  context 'time left rendering' do
    let(:now) { Time.zone.now }
    let(:event) { build(:event, endtime: difference.since(now)) }
    let(:description) do
      Timecop.freeze(now) do
        event.time_left
      end
    end

    context 'precise hours left' do
      let(:difference) { 9.hours }

      it 'display the time left correctly' do
        expect(description).to eq '9 hours'
      end
    end

    context 'precise minutes left' do
      let(:difference) { 12.minutes }

      it 'display the time left correctly' do
        expect(description).to eq '12 minutes'
      end
    end

    context 'precise seconds left' do
      let(:difference) { 50.seconds }

      it 'display the time left correctly' do
        expect(description).to eq '50 seconds'
      end
    end

    context 'minutes and seconds left' do
      let(:difference) { 10.minutes + 50.seconds }

      it 'display the time left correctly' do
        expect(description).to eq '10 minutes'
      end
    end

    context 'hours, minutes and seconds left' do
      let(:difference) { 3.hours + 10.minutes + 50.seconds }

      it 'display the time left correctly' do
        expect(description).to eq '3 hours'
      end
    end

    context 'hours and seconds left' do
      let(:difference) { 2.hours + 30.seconds }

      it 'display the time left correctly' do
        expect(description).to eq '2 hours'
      end
    end

    context 'days left' do
      let(:difference) { 20.days }

      it 'display the time left correctly' do
        expect(description).to eq '20 days'
      end
    end
  end

  context 'scopes' do
    before do
      events
    end

    context 'in_territory' do
      it 'works' do
        expect(described_class.in_territory(Municipality.last.country).count).to eq 1
      end
    end

    context 'visible' do
      it 'works' do
        expect(described_class.visible.count).to eq 0
      end
    end

    context 'not visible' do
      it 'works' do
        expect(described_class.not_visible.count).to eq 3
      end
    end

    context 'votation' do
      it 'works' do
        expect(described_class.votation.count).to eq 0
      end
    end

    context 'after_time' do
      it 'works' do
        expect(described_class.after_time.count).to eq 3
      end
    end

    context 'vote_period' do
      it 'works' do
        expect(described_class.vote_period.count).to eq 0
      end
    end
  end

  context 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_length_of(:description).is_at_most(1.megabyte) }
    it { is_expected.to validate_presence_of(:starttime) }
    it { is_expected.to validate_presence_of(:endtime) }
    it { is_expected.to belong_to(:event_type) }
    it { is_expected.to belong_to(:user) }
  end

  context 'ics format' do
    let(:event) { create(:meeting_event) }

    it 'exports in ics format' do
      ical_event = event.to_ics
      expect(ical_event.dtstart).to eq event.ics_starttime
      expect(ical_event.dtend).to eq event.ics_endtime
    end
  end

  describe '#duration' do
    it 'returns the difference between endtime and starttime' do
      event = build(:event, starttime: 1.day.from_now, endtime: 3.days.from_now)
      expect(event.duration).to be_within(1.second).of(2.days)
    end
  end

  describe '#past?' do
    it 'returns true when endtime is in the past' do
      event = build(:event, starttime: 3.days.ago, endtime: 1.day.ago)
      expect(event.past?).to be true
    end

    it 'returns false when endtime is in the future' do
      event = build(:event, starttime: 1.day.from_now, endtime: 3.days.from_now)
      expect(event.past?).to be false
    end
  end

  describe '#now?' do
    it 'returns true when current time is between starttime and endtime' do
      event = build(:event, starttime: 1.day.ago, endtime: 1.day.from_now)
      expect(event.now?).to be true
    end

    it 'returns false when event has not started' do
      event = build(:event, starttime: 1.day.from_now, endtime: 3.days.from_now)
      expect(event.now?).to be false
    end
  end

  describe '#not_started?' do
    it 'returns true when starttime is in the future' do
      event = build(:event, starttime: 1.day.from_now, endtime: 3.days.from_now)
      expect(event.not_started?).to be true
    end

    it 'returns false when starttime is in the past' do
      event = build(:event, starttime: 1.day.ago, endtime: 1.day.from_now)
      expect(event.not_started?).to be false
    end
  end

  describe '#votation?' do
    it 'returns true for votation events' do
      event = build(:vote_event)
      expect(event.votation?).to be true
    end

    it 'returns false for meeting events' do
      event = build(:meeting_event)
      expect(event.votation?).to be false
    end
  end

  describe '#meeting?' do
    it 'returns true for meeting events' do
      event = build(:meeting_event)
      expect(event.meeting?).to be true
    end

    it 'returns false for votation events' do
      event = build(:vote_event)
      expect(event.meeting?).to be false
    end
  end

  describe '#to_param' do
    it 'returns a SEO-friendly URL parameter with id and title' do
      event = create(:meeting_event, title: 'Hello World Event')
      expect(event.to_param).to include(event.id.to_s)
      expect(event.to_param).to include('hello-world-event')
    end
  end

  describe '#valid_dates?' do
    it 'returns true when starttime is before endtime' do
      event = build(:event, starttime: 1.day.from_now, endtime: 3.days.from_now)
      expect(event.valid_dates?).to be true
    end

    it 'returns false when starttime equals endtime' do
      t = 1.day.from_now
      event = build(:event, starttime: t, endtime: t)
      expect(event.valid_dates?).to be false
    end
  end

  describe '#formatted_starttime' do
    it 'returns a localized string' do
      event = create(:meeting_event)
      expect(event.formatted_starttime).to be_a(String)
    end
  end

  describe '#formatted_endtime' do
    it 'returns a localized string' do
      event = create(:meeting_event)
      expect(event.formatted_endtime).to be_a(String)
    end
  end

  describe '#organizer_id' do
    it 'returns the group id from meeting_organizations' do
      event = create(:meeting_event)
      expect(event.organizer_id).to be_nil # no meeting organization by default
    end
  end

  describe '#set_all_day_time' do
    it 'sets starttime to beginning of day when all_day is true' do
      event = build(:event, all_day: true, starttime: Time.zone.now.change(hour: 14), endtime: 1.day.from_now)
      event.valid?
      expect(event.starttime).to eq(event.starttime.beginning_of_day)
    end
  end
end
