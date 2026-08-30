require 'rails_helper'
require 'requests_helper'

RSpec.describe BlogsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:blog) { create(:blog, user: user, title: "Civic O'Keefe <Review>") }

  describe 'GET index' do
    it 'returns 200 for unauthenticated users' do
      get blogs_path
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.text).to include(blog.title)
    end

    it 'returns 200 for authenticated users' do
      sign_in user
      get blogs_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET show' do
    it 'returns 200 for unauthenticated users' do
      get blog_path(blog)
      expect(response).to have_http_status(:ok)
    end

    it 'returns 200 for authenticated users' do
      sign_in user
      get blog_path(blog)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET new' do
    it 'redirects to sign in when not authenticated' do
      get new_blog_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects or returns error when user already has a blog' do
      sign_in user
      get new_blog_path
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 200 for authenticated user without a blog' do
      user2 = create(:user)
      sign_in user2
      get new_blog_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET edit' do
    it 'redirects to sign in when not authenticated' do
      get edit_blog_path(blog)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns 200 for blog owner' do
      sign_in user
      get edit_blog_path(blog)
      expect(response).to have_http_status(:ok)
    end

    it 'is forbidden for non-owner' do
      other_user = create(:user)
      sign_in other_user
      get edit_blog_path(blog)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST create' do
    it 'redirects to sign in when not authenticated' do
      post blogs_path, params: { blog: { title: 'My Blog' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'creates blog when authenticated user has no blog' do
      user2 = create(:user)
      sign_in user2
      expect {
        post blogs_path, params: { blog: { title: 'New Blog' } }
      }.to change(Blog, :count).by(1)
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(blog_path(Blog.last))
    end
  end

  describe 'PATCH update' do
    it 'redirects to sign in when not authenticated' do
      patch blog_path(blog), params: { blog: { title: 'Updated' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'updates the blog when owner is authenticated' do
      sign_in user
      patch blog_path(blog), params: { blog: { title: 'Updated Title' } }
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(blog_path(blog.reload))
      expect(blog.title).to eq('Updated Title')
    end
  end

  describe 'DELETE destroy' do
    it 'redirects to sign in when not authenticated' do
      delete blog_path(blog)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'destroys the blog when owner is authenticated' do
      sign_in user
      expect {
        delete blog_path(blog)
      }.to change(Blog, :count).by(-1)
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'invalid submissions' do
    it 'returns 422 without creating a blank blog' do
      user2 = create(:user)
      sign_in user2
      expect { post blogs_path, params: { blog: { title: '' } } }.not_to change(Blog, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
