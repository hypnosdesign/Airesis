require 'rails_helper'

RSpec.describe Frm::PostsHelper, type: :helper, seeds: true do
  before do
    allow(helper.request).to receive(:ssl?).and_return(false)
    # Frm.default_gravatar_image / avatar_user_method are leftover from forem gem
    # and not defined in this app — stub them without partial double verification
    RSpec::Mocks.with_temporary_scope do
    end
    Frm.instance_eval do
      def default_gravatar_image; nil; end unless respond_to?(:default_gravatar_image)
      def default_gravatar; nil; end unless respond_to?(:default_gravatar)
      def avatar_user_method; nil; end unless respond_to?(:avatar_user_method)
    end
  end

  describe '#avatar_url' do
    it 'returns a gravatar URL for a given email' do
      url = helper.avatar_url('test@example.com')
      expect(url).to include('gravatar.com/avatar/')
      expect(url).to include('s=60')
    end

    it 'uses https for SSL requests' do
      allow(helper.request).to receive(:ssl?).and_return(true)
      url = helper.avatar_url('test@example.com')
      expect(url).to include('secure.gravatar.com')
    end

    it 'accepts custom size option' do
      url = helper.avatar_url('test@example.com', size: 80)
      expect(url).to include('s=80')
    end

    it 'handles nil email gracefully' do
      url = helper.avatar_url(nil)
      expect(url).to include('gravatar.com/avatar/')
    end
  end

  describe '#default_gravatar' do
    it 'returns nil when no image configured' do
      result = helper.default_gravatar
      expect(result).to be_nil
    end
  end
end
