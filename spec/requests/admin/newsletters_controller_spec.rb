require 'rails_helper'
require 'requests_helper'

RSpec.describe Admin::NewslettersController, seeds: true do
  let!(:admin) { create(:admin) }
  let!(:newsletter) { Newsletter.create!(subject: 'Test Newsletter', body: '<p>Hello</p>') }

  it 'does not route the newsletter area for guests' do
    get admin_newsletters_path

    expect(response).to have_http_status(:not_found)
  end

  context 'when signed in as an administrator' do
    before { sign_in admin }

    it 'renders index, show, new and edit' do
      get admin_newsletters_path
      expect(response).to have_http_status(:ok)

      get admin_newsletter_path(newsletter)
      expect(response).to have_http_status(:ok)

      get new_admin_newsletter_path
      expect(response).to have_http_status(:ok)

      get edit_admin_newsletter_path(newsletter)
      expect(response).to have_http_status(:ok)
    end

    it 'creates with 303 and returns 422 for invalid content' do
      post admin_newsletters_path, params: { newsletter: { subject: 'Update', body: '<p>Body</p>' } }
      expect(response).to have_http_status(:see_other)

      post admin_newsletters_path, params: { newsletter: { subject: '', body: '' } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'updates with 303 and returns 422 for invalid content' do
      patch admin_newsletter_path(newsletter), params: { newsletter: { subject: 'Changed', body: '<p>Body</p>' } }
      expect(response).to have_http_status(:see_other)
      expect(newsletter.reload.subject).to eq('Changed')

      patch admin_newsletter_path(newsletter), params: { newsletter: { subject: '', body: '' } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'previews sanitized markup without evaluating ERB' do
      newsletter.update!(body: '<p>Safe</p><script>alert(1)</script><%= raise "EXECUTED" %>')

      get preview_admin_newsletter_path(newsletter)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Safe')
      expect(response.body).not_to include('<script>')
      expect(response.body).to include('raise')
    end

    it 'queues the allowlisted test audience only' do
      expect do
        patch publish_admin_newsletter_path(newsletter), params: { newsletter: { receiver: 'test' } }
      end.to have_enqueued_job(NewsletterSender).with(newsletter.id, [admin.id])

      expect(response).to have_http_status(:see_other)
      expect(flash[:notice]).to include('1')
    end

    it 'rejects an unknown audience without enqueueing delivery' do
      expect do
        patch publish_admin_newsletter_path(newsletter), params: { newsletter: { receiver: 'unexpected' } }
      end.not_to have_enqueued_job(NewsletterSender)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'deletes a draft with 303' do
      expect do
        delete admin_newsletter_path(newsletter)
      end.to change(Newsletter, :count).by(-1)

      expect(response).to redirect_to(admin_newsletters_path)
      expect(response).to have_http_status(:see_other)
    end
  end
end
