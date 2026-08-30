require 'rails_helper'
require 'requests_helper'

RSpec.describe 'Proposal UI', seeds: true do
  let!(:owner) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: owner.id) }

  it 'renders the proposal listing with a main landmark and accessible filter dialog' do
    get proposals_path

    expect(response).to have_http_status(:ok)
    document = Nokogiri::HTML5(response.body)
    expect(document.css('main#main-content').length).to eq(1)
    expect(document.at_css('[data-right-drawer-target="trigger"]')['aria-controls']).to eq('right-drawer')
    expect(document.at_css('#right-drawer[role="dialog"][aria-labelledby="right-drawer-title"]')).to be_present
    expect(document.css('li.proposal_list article').length).to be >= 1
    sort_links = document.css("nav[aria-label='Sort proposals'] a")
    expect(sort_links).not_to be_empty
    expect(sort_links.map { |link| link['href'] }.grep(%r{/tab_list})).to be_empty
  end

  it 'renders a group listing when the group description is Action Text content' do
    group = create(:group, current_user_id: owner.id)
    group.description = '<p>A group description rendered by Action Text.</p>'
    group.save!
    create(:group_proposal,
           current_user_id: owner.id,
           group_proposals: [GroupProposal.new(group: group)],
           visible_outside: false)
    sign_in owner

    get group_proposals_path(group)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('A group description rendered by Action Text.')
    document = Nokogiri::HTML5(response.body)
    expect(document.at_css("label[for='search']")).to be_present
    expect(document.at_css("label[for='or']")).to be_present
  end

  it 'associates labels with the core new-proposal fields' do
    sign_in owner
    get new_proposal_path, params: { proposal_type_id: 'STANDARD' }

    expect(response).to have_http_status(:ok)
    document = Nokogiri::HTML5(response.body)
    %w[
      proposal_title
      proposal_interest_borders_tkn
      proposal_tags_list
      proposal_proposal_category_id
      proposal_quorum_id
      proposal_sections_attributes_0_paragraphs_attributes_0_content
    ].each do |field_id|
      expect(document.at_css("label[for='#{field_id}']")).to be_present
    end
  end

  it 'renders visible, named Trix editors for persisted proposal content' do
    sign_in owner
    get edit_proposal_path(proposal)

    expect(response).to have_http_status(:ok)
    document = Nokogiri::HTML5(response.body)
    editors = document.css('trix-editor.proposal-editor')
    expect(editors).not_to be_empty
    editors.each do |editor|
      expect(editor['input']).to be_present
      expect(editor['aria-labelledby']).to be_present
      expect(document.at_css("##{editor['aria-labelledby']}")).to be_present
    end
    expect(document.at_css("form[data-controller~='proposal-editor']")).to be_present
    expect(document.css("details[data-proposal-editor-target='section']")).not_to be_empty
    expect(document.css("details[data-proposal-editor-target='section'][open]")).not_to be_empty
    expect(response.body).not_to include('{standard:')
  end

  it 'renders a responsive banner and a complete preview page' do
    get banner_proposal_path(proposal)

    expect(response).to have_http_status(:ok)
    banner = Nokogiri::HTML5.fragment(response.body).at_css('aside')
    expect(banner).to be_present
    expect(banner['style']).to include('width:100%')
    expect(banner['style']).not_to include('width:726px')
    expect(banner.at_css("a[href*='#{proposal.to_param}']")).to be_present

    sign_in owner
    get test_banner_proposal_path(proposal)

    expect(response).to have_http_status(:ok)
    document = Nokogiri::HTML5(response.body)
    expect(document.at_css('main h1')).to be_present
    expect(document.at_css("section[aria-labelledby='banner-preview-heading'] aside")).to be_present
    expect(document.css("script[src*='/banner']")).to be_empty
  end

  it 'persists Trix content_dirty without relying on the removed legacy editor JavaScript' do
    sign_in owner
    section = proposal.sections.first
    paragraph = section.paragraph

    patch proposal_path(proposal), params: {
      proposal: {
        sections_attributes: {
          '0' => {
            id: section.id,
            seq: section.seq,
            title: section.title,
            paragraphs_attributes: {
              '0' => { id: paragraph.id, seq: paragraph.seq, content_dirty: '<p>Updated through Trix</p>' }
            }
          }
        }
      },
      subaction: 'save'
    }

    expect(response).to have_http_status(:ok)
    expect(paragraph.reload.content).to eq('<p>Updated through Trix</p>')
  end
end
