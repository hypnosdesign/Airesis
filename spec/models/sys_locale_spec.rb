require 'rails_helper'

RSpec.describe SysLocale, type: :model, seeds: true do
  describe '.default' do
    it 'returns a default locale' do
      locale = SysLocale.default
      expect(locale).to be_a(SysLocale).or be_nil
    end
  end

  describe '.all' do
    it 'has seeded locales' do
      expect(SysLocale.count).to be > 0
    end
  end

  describe '#host' do
    it 'responds to host' do
      locale = SysLocale.first
      expect(locale).to respond_to(:host)
    end
  end

  describe '#territory' do
    it 'responds to territory' do
      locale = SysLocale.first
      expect(locale).to respond_to(:territory)
    end
  end
end
