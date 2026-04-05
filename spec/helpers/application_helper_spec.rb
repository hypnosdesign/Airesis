require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#to_momentjs' do
    it 'converts %d to dd' do
      result = helper.to_momentjs('%d/%m/%Y')
      expect(result).to include('dd')
    end

    it 'converts %m to mm' do
      result = helper.to_momentjs('%m/%Y')
      expect(result).to include('mm')
    end

    it 'converts %Y to yyyy' do
      result = helper.to_momentjs('%Y')
      expect(result).to include('yyyy')
    end

    it 'converts %H to hh' do
      result = helper.to_momentjs('%H:%M')
      expect(result).to include('hh')
    end

    it 'converts %M to ii' do
      result = helper.to_momentjs('%H:%M')
      expect(result).to include('ii')
    end
  end

  describe '#facebook_like' do
    it 'returns a div with fb-like class' do
      result = helper.facebook_like
      expect(result).to include('fb-like')
    end
  end

  describe '#calendar' do
    it 'returns a div with id calendar' do
      result = helper.calendar
      expect(result).to include('calendar')
    end
  end

  describe '#resource_name' do
    it 'returns :user' do
      expect(helper.resource_name).to eq(:user)
    end
  end

  describe '#resource' do
    it 'returns a new User' do
      expect(helper.resource).to be_a(User)
    end
  end

  describe '#time_in_words' do
    it 'returns a countdown div for time less than 1 hour ago today' do
      from_time = 30.minutes.ago
      result = helper.time_in_words(from_time)
      expect(result).to include('data-countdown')
    end

    it 'returns hour format for time more than 1 hour ago today' do
      from_time = 2.hours.ago
      result = helper.time_in_words(from_time)
      expect(result).to be_a(String)
    end

    it 'returns yesterday format for yesterday' do
      from_time = 1.day.ago
      result = helper.time_in_words(from_time)
      expect(result).to be_a(String)
    end

    it 'returns short format for older dates' do
      from_time = 10.days.ago
      result = helper.time_in_words(from_time)
      expect(result).to be_a(String)
    end
  end

  describe '#body_page_name' do
    it 'returns nil when response is not successful' do
      allow(helper).to receive(:response).and_return(nil)
      result = helper.body_page_name
      expect(result).to be_nil
    end
  end

  describe '#add_params' do
    it 'merges params excluding controller and action' do
      allow(helper).to receive(:params).and_return(
        ActionController::Parameters.new(controller: 'home', action: 'index', page: '2')
      )
      result = helper.add_params(sort: 'asc')
      expect(result[:sort]).to eq('asc')
      expect(result[:page]).to eq('2')
      expect(result).not_to have_key('controller')
    end
  end
end
