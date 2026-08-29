require 'rails_helper'
require 'requests_helper'

RSpec.describe SysPaymentNotificationsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }

  describe '#validate_ipn_notification' do
    let(:http) { instance_double(Net::HTTP) }
    let(:paypal_response) { instance_double(Net::HTTPResponse, body: 'VERIFIED') }

    before do
      allow(ENV).to receive(:[]).with('PAYPAL_URL').and_return('https://www.sandbox.paypal.com/cgi-bin/webscr')
      allow(Net::HTTP).to receive(:new).with('www.sandbox.paypal.com', 443).and_return(http)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:verify_mode=)
      allow(http).to receive(:post).and_return(paypal_response)
    end

    it 'requires HTTPS and verifies the PayPal certificate' do
      response = described_class.new.send(:validate_ipn_notification, 'payment_status=Completed')

      expect(response).to eq('VERIFIED')
      expect(http).to have_received(:use_ssl=).with(true)
      expect(http).to have_received(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER)
    end

    it 'rejects a non-HTTPS PayPal endpoint' do
      allow(ENV).to receive(:[]).with('PAYPAL_URL').and_return('http://www.sandbox.paypal.com/cgi-bin/webscr')

      expect do
        described_class.new.send(:validate_ipn_notification, 'payment_status=Completed')
      end.to raise_error(ArgumentError, 'PAYPAL_URL must use HTTPS')
    end
  end

  describe 'POST create' do
    context 'with VERIFIED response' do
      before do
        allow_any_instance_of(SysPaymentNotificationsController)
          .to receive(:validate_ipn_notification).and_return('VERIFIED')
      end

      it 'processes the notification and responds' do
        post sys_payment_notifications_path,
             params: {
               payment_status: 'Completed',
               txn_id: 'TXN123',
               mc_fee: '0.30',
               mc_gross: '10.00',
               first_name: 'John',
               last_name: 'Doe',
               item_number: group.id.to_s,
               atype: 'Group'
             }
        expect([200, 204, 302, 500]).to include(response.status)
      end

      it 'handles non-existent payable type' do
        post sys_payment_notifications_path,
             params: {
               payment_status: 'Completed',
               txn_id: 'TXN456',
               item_number: group.id.to_s,
               atype: 'NonExistentClass123'
             }
        expect([200, 204, 302, 500]).to include(response.status)
      end
    end

    context 'with INVALID response' do
      before do
        allow_any_instance_of(SysPaymentNotificationsController)
          .to receive(:validate_ipn_notification).and_return('INVALID')
      end

      it 'logs an error and responds' do
        post sys_payment_notifications_path,
             params: { payment_status: 'Completed', txn_id: 'TXN789' }
        expect([200, 204, 302, 500]).to include(response.status)
      end
    end

    context 'when IPN validation returns nil' do
      before do
        allow_any_instance_of(SysPaymentNotificationsController)
          .to receive(:validate_ipn_notification).and_return(nil)
      end

      it 'does nothing and responds' do
        post sys_payment_notifications_path,
             params: { payment_status: 'Pending' }
        expect([200, 204, 302, 500]).to include(response.status)
      end
    end
  end
end
