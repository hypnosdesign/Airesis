require 'rails_helper'
require 'requests_helper'

RSpec.describe DocumentsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }
  let(:storage_root) { Pathname(Dir.mktmpdir('airesis-documents-spec')) }
  let(:document_root) { storage_root.join(group.id.to_s) }

  around do |example|
    previous_root = ENV.fetch('DOCUMENTS_STORAGE_ROOT', nil)
    ENV['DOCUMENTS_STORAGE_ROOT'] = storage_root.to_s
    example.run
  ensure
    ENV['DOCUMENTS_STORAGE_ROOT'] = previous_root
  end

  after do
    FileUtils.remove_entry(storage_root) if storage_root.exist?
  end

  describe 'GET index' do
    it 'redirects to sign in when not authenticated' do
      get "/groups/#{group.to_param}/documents"
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated as group owner' do
      sign_in user
      get "/groups/#{group.to_param}/documents"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t('pages.groups.documents.empty_title'))
    end

    it 'calculates current usage without writing during a GET' do
      document_root.mkpath
      document_root.join('agenda.txt').write('Shared agenda')
      group.update!(actual_storage_size: 7)
      sign_in user

      get group_documents_path(group)

      expect(response).to have_http_status(:ok)
      expect(group.reload.actual_storage_size).to eq(7)
    end
  end

  describe 'document lifecycle' do
    before { sign_in user }

    it 'uploads, serves, downloads, and removes a document' do
      upload = Tempfile.new(['agenda', '.txt'])
      upload.write('Shared agenda')
      upload.rewind
      uploaded_file = Rack::Test::UploadedFile.new(upload.path, 'text/plain', original_filename: 'agenda.txt')

      post upload_group_documents_path(group), params: { document: uploaded_file }
      expect(response).to have_http_status(:see_other)
      expect(document_root.join('agenda.txt').read).to eq('Shared agenda')

      get view_group_documents_path(group), params: { path: 'agenda.txt' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq('Shared agenda')
      expect(response.headers['Content-Disposition']).to include('inline')

      get view_group_documents_path(group), params: { path: 'agenda.txt', download: 1 }
      expect(response.headers['Content-Disposition']).to include('attachment')

      delete remove_group_documents_path(group), params: { path: 'agenda.txt' }
      expect(response).to have_http_status(:see_other)
      expect(document_root.join('agenda.txt')).not_to exist
    ensure
      upload&.close!
    end

    it 'rejects traversal outside the group directory' do
      get view_group_documents_path(group), params: { path: '../secrets.txt' }
      expect(response).to have_http_status(:not_found)
    end

    it 'rejects a path through an intermediate symlink' do
      outside_root = Pathname(Dir.mktmpdir('airesis-documents-outside'))
      outside_root.join('secret.txt').write('secret')
      document_root.mkpath
      document_root.join('linked').make_symlink(outside_root)

      get view_group_documents_path(group), params: { path: 'linked/secret.txt' }

      expect(response).to have_http_status(:not_found)
    ensure
      FileUtils.remove_entry(outside_root) if outside_root&.exist?
    end

    it 'serves active content as an attachment' do
      document_root.mkpath
      document_root.join('page.html').write('<script>alert(1)</script>')

      get view_group_documents_path(group), params: { path: 'page.html' }

      expect(response).to have_http_status(:ok)
      expect(response.headers['Content-Disposition']).to include('attachment')
    end

    it 'requires a selected file' do
      post upload_group_documents_path(group)
      expect(response).to have_http_status(:see_other)
      expect(flash[:alert]).to eq(I18n.t('pages.groups.documents.upload_missing'))
    end
  end
end
