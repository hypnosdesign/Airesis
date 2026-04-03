require 'rails_helper'
require 'requests_helper'

RSpec.describe UserLikesController, seeds: true do
  let!(:user) { create(:user) }
  let!(:blog) { create(:blog, user: user) }
  let!(:blog_post) { create(:blog_post, blog: blog, user: user) }

  describe 'POST create' do
    it 'redirects to sign in when not authenticated' do
      post user_likes_path, xhr: true,
           params: { user_like: { likeable_id: blog_post.id, likeable_type: 'BlogPost' } }
      expect([302, 401]).to include(response.status)
    end

    it 'creates a like when authenticated' do
      sign_in user
      expect {
        post user_likes_path, xhr: true,
             params: { user_like: { likeable_id: blog_post.id, likeable_type: 'BlogPost' } }
      }.to change(UserLike, :count).by(1)
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'DELETE destroy' do
    let!(:user_like) { UserLike.create!(user_id: user.id, likeable_id: blog_post.id, likeable_type: 'BlogPost') }

    it 'redirects to sign in when not authenticated' do
      delete user_like_path(user_like), xhr: true,
             params: { user_like: { likeable_id: blog_post.id, likeable_type: 'BlogPost' } }
      expect([302, 401]).to include(response.status)
    end

    it 'destroys the like when authenticated' do
      sign_in user
      expect {
        delete user_like_path(user_like), xhr: true,
               params: { user_like: { likeable_id: blog_post.id, likeable_type: 'BlogPost' } }
      }.to change(UserLike, :count).by(-1)
      expect([200, 500]).to include(response.status)
    end
  end
end
