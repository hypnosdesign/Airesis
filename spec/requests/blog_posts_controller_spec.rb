require 'rails_helper'
require 'requests_helper'

RSpec.describe BlogPostsController, seeds: true do
  let!(:user) { create(:user) }

  describe 'GET index' do
    let(:group) { create(:group, current_user_id: user.id) }
    let(:blog) { create(:blog, user: user) }
    let!(:posts) { create_list(:blog_post, 3, blog: blog, user: user) }

    it 'redirects to the group' do
      get blog_posts_path, params: { group_id: group.id }
      expect(response.code).to eq('302')
      expect(response).to redirect_to(group)
    end

    it 'redirects to the blog' do
      get blog_posts_path, params: { blog_id: blog.id }
      expect(response.code).to eq('302')
      expect(response).to redirect_to(blog)
    end

    it 'show public posts' do
      get blog_posts_path
      expect(response).to have_http_status(:ok)
      expect(CGI.unescapeHTML(response.body)).to include(*posts.map(&:title))
    end

    it 'do not show reserved posts' do
      blog_post = create(:blog_post, blog: blog, user: user, status: BlogPost::RESERVED)
      get blog_posts_path
      expect(response.body).not_to include(blog_post.title)
    end

    it 'do not show drafts posts' do
      blog_post = create(:blog_post, blog: blog, user: user, status: BlogPost::DRAFT)
      get blog_posts_path
      expect(response.body).not_to include(blog_post.title)
    end
  end

  describe 'GET new' do
    it "can't create blog post if has not a blog" do
      group = create(:group, current_user_id: user.id)
      sign_in user
      get new_group_blog_post_path(group)
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns a response when user has a blog' do
      blog = create(:blog, user: user)
      sign_in user
      get new_blog_blog_post_path(blog)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET show' do
    let(:blog) { create(:blog, user: user) }
    let!(:post) { create(:blog_post, blog: blog, user: user) }

    it 'returns a response for public post' do
      get blog_post_path(post)
      expect(response).to have_http_status(:ok)
    end

    it 'returns a response when authenticated' do
      sign_in user
      get blog_blog_post_path(blog, post)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST create' do
    let(:blog) { create(:blog, user: user) }

    it 'redirects to sign in when not authenticated' do
      post blog_blog_posts_path(blog), params: { blog_post: { title: 'My Post', body: 'Content', status: BlogPost::PUBLISHED } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated' do
      sign_in user
      expect do
        post blog_blog_posts_path(blog), params: {
          blog_post: { title: 'My Post', body: 'Content', status: BlogPost::PUBLISHED }
        }
      end.to change(BlogPost, :count).by(1)
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(blog_path(blog))
    end
  end

  describe 'DELETE destroy' do
    let(:blog) { create(:blog, user: user) }
    let!(:post) { create(:blog_post, blog: blog, user: user) }

    it 'redirects to sign in when not authenticated' do
      delete blog_blog_post_path(blog, post)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated as owner' do
      sign_in user
      expect { delete blog_blog_post_path(blog, post) }.to change(BlogPost, :count).by(-1)
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(blog_path(blog))
    end
  end

  describe 'GET edit' do
    let(:blog) { create(:blog, user: user) }
    let!(:post) { create(:blog_post, blog: blog, user: user) }

    it 'redirects to sign in when not authenticated' do
      get edit_blog_blog_post_path(blog, post)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for the author' do
      sign_in user
      get edit_blog_blog_post_path(blog, post)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH update' do
    let(:blog) { create(:blog, user: user) }
    let!(:post) { create(:blog_post, blog: blog, user: user) }

    it 'redirects to sign in when not authenticated' do
      patch blog_blog_post_path(blog, post), params: { blog_post: { title: 'Updated' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'updates the post when authenticated as author' do
      sign_in user
      patch blog_blog_post_path(blog, post), params: {
        blog_post: { title: 'Updated Title', body: 'Updated body', status: BlogPost::PUBLISHED }
      }
      expect(post.reload.title).to eq('Updated Title')
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(blog_blog_post_path(blog, post))
    end
  end

  describe 'GET drafts' do
    let(:blog) { create(:blog, user: user) }

    it 'redirects to sign in when not authenticated' do
      get drafts_blog_blog_posts_path(blog)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated' do
      sign_in user
      get drafts_blog_blog_posts_path(blog)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'invalid state' do
    let(:blog) { create(:blog, user: user) }

    it 'rejects unsupported publication values' do
      sign_in user
      expect do
        post blog_blog_posts_path(blog), params: {
          blog_post: { title: 'Invalid state', body: 'Content', status: 'X' }
        }
      end.not_to change(BlogPost, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
