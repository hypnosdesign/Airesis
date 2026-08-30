require 'rails_helper'
require 'requests_helper'

RSpec.describe 'the blog posts process', :js, seeds: true do
  let!(:user) { create(:user) }
  let!(:blog) { create(:blog, user: user) }

  before do
    login_as user, scope: :user
  end

  after do
    logout(:user)
  end

  it 'can insert a blog_post in his blog and edit it' do
    visit blog_path(blog)
    expect(page).to have_content(I18n.t('pages.blog_posts.new_button'))
    click_link I18n.t('pages.blog_posts.new_button')
    expect(page).to have_content(I18n.t('pages.blog_posts.new_button'))
    blog_post_name = Faker::Company.name
    # fill form fields

    within('main#main-content') do
      fill_in I18n.t('activerecord.attributes.blog_post.title'), with: blog_post_name
      find('trix-editor').set(Faker::Lorem.paragraph)
      click_button I18n.t('buttons.save')
    end

    # the group name is certainly displayed somewhere
    expect(page).to have_content blog_post_name

    within('#blogPostContainer') do
      click_link blog_post_name
    end
    created_post = BlogPost.find_by!(title: blog_post_name)
    click_link I18n.t('pages.blog_posts.show.edit_button'), href: edit_blog_blog_post_path(blog, created_post)

    # fill form fields
    blog_post_title = Faker::Company.name
    within('main#main-content') do
      fill_in I18n.t('activerecord.attributes.blog_post.title'), with: blog_post_title
      click_button I18n.t('buttons.save')
    end
    # success message!
    expect(page).to have_content(I18n.t('info.blog_post_updated'))
    # the new blog name is certainly displayed somewhere
    expect(page).to have_content blog_post_title
  end

  it 'can insert a blog_post in his group and edit it' do
    @ability = Ability.new(user)
    group = create(:group, current_user_id: user.id)
    visit group_path(group)

    expect(page).to have_content group.name
    click_link I18n.t('pages.groups.show.post_button')

    blog_post_name = Faker::Company.name
    # fill form fields
    within('main#main-content') do
      fill_in I18n.t('activerecord.attributes.blog_post.title'), with: blog_post_name
      find('trix-editor').set(Faker::Lorem.paragraph)
      click_button I18n.t('buttons.save')
    end

    # success message!
    expect(page).to have_content(I18n.t('info.blog_created'))
    # the group name is certainly displayed somewhere
    expect(page).to have_content group.name
    expect(page).to have_content blog_post_name

    within('#posts_container') do
      click_link blog_post_name
    end
    created_post = BlogPost.find_by!(title: blog_post_name)
    click_link I18n.t('pages.blog_posts.show.edit_button'), href: edit_group_blog_post_path(group, created_post)
    # fill form fields
    blog_post_title = Faker::Company.name
    within('main#main-content') do
      fill_in I18n.t('activerecord.attributes.blog_post.title'), with: blog_post_title
      click_button I18n.t('buttons.save')
    end
    # success message!
    expect(page).to have_content(I18n.t('info.blog_post_updated'))
    # the new blog name is certainly displayed somewhere
    expect(page).to have_content blog_post_title
  end

  it 'can delete his blog posts' do
    blog_post = create(:blog_post, blog: blog, user: user)
    visit blog_blog_post_path(blog, blog_post)
    find('summary', text: I18n.t('pages.blog_posts.show.delete_button')).click
    click_button I18n.t('pages.blog_posts.show.confirm_delete_button')
    expect(page).to have_current_path(blog_path(blog))
    expect(page).to have_content(I18n.t('info.blog_post_deleted'))
  end

  it 'can delete published posts' do
    group = create(:group, current_user_id: user.id)
    blog_post = create(:blog_post, blog: blog, user: user)
    blog_post.groups << group
    blog_post.save

    visit group_blog_post_path(group, blog_post)
    find('summary', text: I18n.t('pages.blog_posts.show.delete_button')).click
    click_button I18n.t('pages.blog_posts.show.confirm_delete_button')
    expect(page).to have_current_path(group_path(group))
    expect(page).to have_content(I18n.t('info.blog_post_deleted'))
  end

  it 'keeps the destructive confirmation fully visible on mobile' do
    blog_post = create(:blog_post, blog: blog, user: user)
    page.current_window.resize_to(390, 844)

    visit blog_blog_post_path(blog, blog_post)
    find('summary', text: I18n.t('pages.blog_posts.show.delete_button')).click

    bounds = page.evaluate_script(<<~JS)
      (() => {
        const rect = document.querySelector('[data-delete-confirmation]').getBoundingClientRect();
        return { left: rect.left, right: rect.right, viewport: window.innerWidth };
      })()
    JS
    expect(bounds['left']).to be >= 0
    expect(bounds['right']).to be <= bounds['viewport']
  ensure
    page.current_window.resize_to(1400, 900)
  end
end
