require 'rails_helper'

RSpec.describe User::Socializable, type: :model, seeds: true do
  let!(:user) { create(:user) }

  describe '#is_my_blog_post?' do
    let!(:blog) { create(:blog, user: user) }
    let!(:blog_post) { create(:blog_post, blog: blog, user: user) }

    it 'returns true when the blog post belongs to the user' do
      expect(user.is_my_blog_post?(blog_post.id)).to be true
    end

    it 'returns false when the blog post does not belong to the user' do
      other_user = create(:user)
      expect(other_user.is_my_blog_post?(blog_post.id)).to be false
    end
  end

  describe '#is_my_blog?' do
    let!(:blog) { create(:blog, user: user) }

    it 'returns true when the blog belongs to the user' do
      expect(user.is_my_blog?(blog.id)).to be true
    end

    it 'returns falsy when the blog does not belong to the user' do
      other_user = create(:user)
      expect(other_user.is_my_blog?(blog.id)).to be_falsy
    end

    it 'returns falsy when user has no blog' do
      other_user = create(:user)
      expect(other_user.is_my_blog?(blog.id)).to be_falsy
    end
  end
end
