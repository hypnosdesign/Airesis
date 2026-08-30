require 'rails_helper'
require 'requests_helper'

RSpec.describe UserLikesController, seeds: true do
  let!(:author) { create(:user) }
  let!(:blog) { create(:blog, user: author) }
  let!(:blog_post) { create(:blog_post, blog: blog, user: author) }

  describe 'POST create' do
    it 'creates a like for the authenticated user' do
      sign_in author
      expect {
        post user_likes_path, params: { user_like: { likeable_id: blog_post.id, likeable_type: 'BlogPost' } }
      }.to change(UserLike.where(user_id: author.id), :count).by(1)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'DELETE destroy' do
    let!(:user_like) { UserLike.create!(user_id: author.id, likeable_id: blog_post.id, likeable_type: 'BlogPost') }

    it 'destroys the current user like' do
      sign_in author
      expect {
        delete user_like_path(user_like), params: { user_like: { likeable_id: blog_post.id, likeable_type: 'BlogPost' } }
      }.to change(UserLike, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end

    it 'cannot destroy another user like' do
      sign_in create(:user)
      expect {
        delete user_like_path(user_like), params: { user_like: { likeable_id: blog_post.id, likeable_type: 'BlogPost' } }
      }.not_to change(UserLike, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
end
