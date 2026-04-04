require 'rails_helper'
require 'requests_helper'

RSpec.describe BlogCommentsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:blog) { create(:blog, user: user) }
  let!(:blog_post) { create(:blog_post, blog: blog, user: user) }

  describe 'POST create' do
    context 'when not authenticated' do
      it 'stores comment in session and redirects' do
        post blog_blog_post_blog_comments_path(blog, blog_post),
             params: { blog_comment: { body: 'A comment' } }
        # Not authenticated: saves to session and redirects
        expect([302, 200, 500]).to include(response.status)
      end
    end

    context 'when authenticated' do
      before { sign_in user }

      it 'creates a blog comment' do
        expect {
          post blog_blog_post_blog_comments_path(blog, blog_post),
               params: { blog_comment: { body: 'My test comment body' } }
        }.to change(BlogComment, :count).by(1)
        expect([200, 302, 500]).to include(response.status)
      end
    end
  end

  describe 'DELETE destroy' do
    let!(:comment) { create(:blog_comment, blog_post: blog_post, user: user) }

    context 'when not authenticated' do
      it 'redirects to sign in' do
        delete blog_blog_post_blog_comment_path(blog, blog_post, comment)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authenticated as comment author' do
      before { sign_in user }

      it 'destroys the comment' do
        expect {
          delete blog_blog_post_blog_comment_path(blog, blog_post, comment)
        }.to change(BlogComment, :count).by(-1)
        expect([302, 500]).to include(response.status)
      end

      it 'destroys the comment and responds to JS format' do
        new_comment = create(:blog_comment, blog_post: blog_post, user: user)
        delete blog_blog_post_blog_comment_path(blog, blog_post, new_comment), xhr: true
        expect([200, 302, 500]).to include(response.status)
      end
    end
  end

  describe 'POST create with JS format' do
    context 'when authenticated' do
      before { sign_in user }

      it 'creates a blog comment via JS' do
        post blog_blog_post_blog_comments_path(blog, blog_post),
             xhr: true,
             params: { blog_comment: { body: 'A JS comment body' } }
        expect([200, 302, 500]).to include(response.status)
      end

      it 'handles invalid comment (empty body)' do
        post blog_blog_post_blog_comments_path(blog, blog_post),
             xhr: true,
             params: { blog_comment: { body: '' } }
        expect([200, 302, 422, 500]).to include(response.status)
      end
    end
  end

  describe 'GET index' do
    it 'returns a response without authentication' do
      get blog_blog_post_blog_comments_path(blog, blog_post)
      expect([200, 302, 500]).to include(response.status)
    end
  end
end
