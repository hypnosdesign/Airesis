require 'rails_helper'

RSpec.describe BlogPost do
  context 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_most(1.megabyte) }
  end

  describe '#published?' do
    it 'returns true when status is PUBLISHED' do
      post = build(:blog_post, status: BlogPost::PUBLISHED)
      expect(post.published?).to be true
    end

    it 'returns false when status is DRAFT' do
      post = build(:blog_post, status: BlogPost::DRAFT)
      expect(post.published?).to be false
    end
  end

  describe '#draft?' do
    it 'returns true when status is DRAFT' do
      post = build(:blog_post, status: BlogPost::DRAFT)
      expect(post.draft?).to be true
    end

    it 'returns false when status is PUBLISHED' do
      post = build(:blog_post, status: BlogPost::PUBLISHED)
      expect(post.draft?).to be false
    end
  end

  describe '#reserved?' do
    it 'returns true when status is RESERVED' do
      post = build(:blog_post, status: BlogPost::RESERVED)
      expect(post.reserved?).to be true
    end

    it 'returns false when status is PUBLISHED' do
      post = build(:blog_post, status: BlogPost::PUBLISHED)
      expect(post.reserved?).to be false
    end
  end

  describe '#formatted_updated_at' do
    it 'returns a formatted string' do
      post = create(:blog_post)
      expect(post.formatted_updated_at).to be_a(String)
      expect(post.formatted_updated_at).to match(%r{\d{2}/\d{2}/\d{4}})
    end
  end

  describe '#to_param' do
    it 'returns a SEO-friendly URL parameter' do
      post = create(:blog_post, title: 'Hello World Test')
      expect(post.to_param).to include(post.id.to_s)
      expect(post.to_param).to include('Hello-World-Test')
    end
  end

  describe '#check_published' do
    it 'sets published_at when status changes from DRAFT to PUBLISHED' do
      post = create(:blog_post, status: BlogPost::DRAFT)
      expect(post.published_at).to be_nil
      post.update(status: BlogPost::PUBLISHED)
      expect(post.published_at).to be_present
    end

    it 'does not overwrite published_at if already set' do
      original_time = 1.day.ago
      post = create(:blog_post, status: BlogPost::PUBLISHED, published_at: original_time)
      post.update(body: 'Updated body')
      expect(post.published_at).to be_within(1.second).of(original_time)
    end
  end

  describe 'scopes' do
    let!(:user) { create(:user) }
    let!(:blog) { create(:blog, user: user) }

    it '.published returns only published and reserved posts' do
      published = create(:blog_post, blog: blog, user: user, status: BlogPost::PUBLISHED)
      reserved = create(:blog_post, blog: blog, user: user, status: BlogPost::RESERVED)
      draft = create(:blog_post, blog: blog, user: user, status: BlogPost::DRAFT)
      expect(BlogPost.published).to include(published, reserved)
      expect(BlogPost.published).not_to include(draft)
    end

    it '.drafts returns only draft posts' do
      published = create(:blog_post, blog: blog, user: user, status: BlogPost::PUBLISHED)
      draft = create(:blog_post, blog: blog, user: user, status: BlogPost::DRAFT)
      expect(BlogPost.drafts).to include(draft)
      expect(BlogPost.drafts).not_to include(published)
    end
  end
end
