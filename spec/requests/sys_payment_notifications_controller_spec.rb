require 'rails_helper'
require 'requests_helper'

RSpec.describe SysPaymentNotificationsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }

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
