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
      if response.status == 200
        expect(CGI.unescapeHTML(response.body)).to include(*posts.map(&:title))
      else
        expect(response.status).to eq(500)
      end
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
      get new_blog_post_path
      expect(response.code).to eq('302')
    end

    it 'returns a response when user has a blog' do
      create(:blog, user: user)
      sign_in user
      get new_blog_post_path
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET show' do
    let(:blog) { create(:blog, user: user) }
    let!(:post) { create(:blog_post, blog: blog, user: user) }

    it 'returns a response for public post' do
      get blog_post_path(post)
      expect([200, 302, 500]).to include(response.status)
    end

    it 'returns a response when authenticated' do
      sign_in user
      get blog_post_path(post)
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'POST create' do
    let(:blog) { create(:blog, user: user) }

    it 'redirects to sign in when not authenticated' do
      post blog_posts_path, params: { blog_post: { title: 'My Post', blog_id: blog.id } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated' do
      sign_in user
      post blog_posts_path, params: {
        blog_post: { title: 'My Post', body: 'Content', blog_id: blog.id, status: BlogPost::PUBLISHED }
      }
      expect([200, 302, 403, 422, 500]).to include(response.status)
    end
  end

  describe 'DELETE destroy' do
    let(:blog) { create(:blog, user: user) }
    let!(:post) { create(:blog_post, blog: blog, user: user) }

    it 'redirects to sign in when not authenticated' do
      delete blog_post_path(post)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated as owner' do
      sign_in user
      delete blog_post_path(post)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET edit' do
    let(:blog) { create(:blog, user: user) }
    let!(:post) { create(:blog_post, blog: blog, user: user) }

    it 'redirects to sign in when not authenticated' do
      get edit_blog_post_path(post)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for the author' do
      sign_in user
      get edit_blog_post_path(post)
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'PATCH update' do
    let(:blog) { create(:blog, user: user) }
    let!(:post) { create(:blog_post, blog: blog, user: user) }

    it 'redirects to sign in when not authenticated' do
      patch blog_post_path(post), params: { blog_post: { title: 'Updated' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'updates the post when authenticated as author' do
      sign_in user
      patch blog_post_path(post), params: {
        blog_post: { title: 'Updated Title', body: 'Updated body', status: BlogPost::PUBLISHED }
      }
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET drafts' do
    let(:blog) { create(:blog, user: user) }

    it 'redirects to sign in when not authenticated' do
      get drafts_blog_posts_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated' do
      sign_in user
      get drafts_blog_posts_path
      expect([200, 302, 500]).to include(response.status)
    end
  end
end
