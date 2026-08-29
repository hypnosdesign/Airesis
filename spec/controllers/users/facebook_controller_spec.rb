require 'rails_helper'

RSpec.describe Users::FacebookController, type: :controller do
  describe '#setup' do
    it 'keeps TLS certificate verification enabled' do
      strategy = Struct.new(:options).new({})
      request = instance_double(ActionDispatch::Request, env: { 'omniauth.strategy' => strategy })
      controller = described_class.new

      allow(controller).to receive(:request).and_return(request)
      allow(controller).to receive(:render)

      controller.setup

      expect(strategy.options[:scope]).to eq('email')
      expect(strategy.options.dig(:client_options, :ssl, :verify)).to be(true)
    end
  end
end
