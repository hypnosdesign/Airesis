require 'rails_helper'

RSpec.describe InterestBorder, type: :model, seeds: true do
  let!(:province) { create(:province) }

  describe '.to_key' do
    it 'creates a key for a Province' do
      key = described_class.to_key(province)
      expect(key).to eq "P-#{province.id}"
    end
  end

  describe '.find_or_create_by_key' do
    it 'returns nil for a blank key' do
      expect(described_class.find_or_create_by_key('')).to be_nil
      expect(described_class.find_or_create_by_key(nil)).to be_nil
    end

    it 'finds or creates an interest border from a Province key' do
      key = "P-#{province.id}"
      border = described_class.find_or_create_by_key(key)
      expect(border).to be_a described_class
      expect(border.territory_type).to eq InterestBorder::PROVINCE
      expect(border.territory_id.to_i).to eq province.id
    end

    it 'is idempotent (second call returns same record)' do
      key = "P-#{province.id}"
      border1 = described_class.find_or_create_by_key(key)
      border2 = described_class.find_or_create_by_key(key)
      expect(border1.id).to eq border2.id
    end
  end

  describe '#key' do
    it 'returns the correct key format' do
      border = described_class.find_or_create_by_key("P-#{province.id}")
      expect(border.key).to eq "P-#{province.id}"
    end
  end

  describe '#text' do
    it 'returns the territory name' do
      border = described_class.find_or_create_by_key("P-#{province.id}")
      expect(border.text).to eq province.name
    end
  end

  describe '#as_json' do
    it 'returns id and text' do
      border = described_class.find_or_create_by_key("P-#{province.id}")
      json = border.as_json
      expect(json[:id]).to eq "P-#{province.id}"
      expect(json[:text]).to eq province.name
    end
  end

  describe 'territory type helpers' do
    it '#is_province? returns true for a province border' do
      border = described_class.find_or_create_by_key("P-#{province.id}")
      expect(border.is_province?).to be_truthy
      expect(border.is_municipality?).to be_falsey
    end

    it '#province returns the territory for a province border' do
      border = described_class.find_or_create_by_key("P-#{province.id}")
      expect(border.province).to eq province
    end
  end
end
