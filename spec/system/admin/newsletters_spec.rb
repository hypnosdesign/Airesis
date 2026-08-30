require 'rails_helper'
require 'requests_helper'
require 'cancan/matchers'

RSpec.describe 'the management of the newsletters', js: true do
  let!(:admin) { create(:admin) }
  let(:newsletters) { create_list(:newsletter, 5) }
  let(:newsletter) { create(:newsletter) }

  before do
    login_as admin, scope: :user
  end

  after do
    logout :user
  end

  it 'can list newsletters' do
    newsletters
    visit admin_newsletters_path
    newsletters.each do |newsletter|
      expect(page).to have_content(newsletter.subject)
    end
  end

  it 'keeps the operations and delivery surfaces usable at mobile width' do
    page.driver.browser.manage.window.resize_to(390, 844)

    visit admin_panel_path
    expect(page).to have_css('main h1', text: I18n.t('admin_ui.panel.title'))
    expect(page.evaluate_script('document.documentElement.scrollWidth <= document.documentElement.clientWidth')).to be(true)

    visit admin_newsletter_path(newsletter)
    expect(page).to have_css('main h1', text: newsletter.subject)
    expect(page).to have_select('newsletter_receiver', options: Newsletter::RECEIVERS.map { |receiver| I18n.t("admin_ui.newsletters.audiences.#{receiver}", count: newsletter.recipient_count(receiver: receiver, test_user_id: admin.id)) })
    expect(page.evaluate_script('document.documentElement.scrollWidth <= document.documentElement.clientWidth')).to be(true)
  end
end
