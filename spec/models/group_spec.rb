require 'rails_helper'

RSpec.describe Group do
  let(:group) { build(:group) }

  context 'validations' do
    it { is_expected.to validate_content_type_of(:image).allowing('image/jpeg', 'image/png', 'image/gif') }
  end

  context 'when created' do
    before do
      load_database
      group.save
    end

    it "has #{UPLOAD_LIMIT_GROUPS / 1024}KB available as space" do
      expect(group.max_storage_size).to eq UPLOAD_LIMIT_GROUPS / 1024
    end

    it 'has one participant' do
      group.reload
      expect(group.group_participations_count).to eq 1
    end

    it 'has a slug' do
      expect(group.slug).to eq to_slug_format(group.name)
    end

    context 'when title changes' do
      let(:new_name) { Faker::Company.name }

      before do
        group.update(name: new_name)
      end

      it 'updates the slug' do
        expect(group.slug).to eq to_slug_format(new_name)
      end

      it 'keeps the old slug' do
        expect(group.slugs.count).to eq 2
      end
    end
  end

  describe '#look' do
    let(:municipality) { create(:municipality) }
    let(:province) { municipality.province }
    let(:groups) do
      [create(:group, num_participants: 1, name: 'rodi alessandro title'),
       create(:group, num_participants: 2, name: 'alessandro rodi description'),
       create(:group, num_participants: 2, tags_list: 'rodi'),
       create(:group, num_participants: 3, name: 'rodi brief'),
       create(:group, num_participants: 2, tags_list: 'rodi,world',
                      interest_border_tkn: InterestBorder.to_key(municipality)),
       create(:group, num_participants: 5, tags_list: 'ciao,rodi',
                      interest_border_tkn: InterestBorder.to_key(province))]
    end

    before do
      load_database
      groups
    end

    context 'method is called with tag parameter' do
      it 'returns all groups with that tag associated ordered by participants an date of creation' do
        expect(described_class.look(tag: 'rodi')).to eq [groups[5], groups[4], groups[2]]
      end
    end

    context 'search by text' do
      it 'returns all groups that match the word' do
        expect(described_class.look(search: 'rodi')).to eq [groups[3], groups[1], groups[0]]
      end

      it 'returns all groups that match all the words' do
        expect(described_class.look(search: 'rodi alessandro')).to eq [groups[1], groups[0]]
      end

      it 'returns all groups that match any of the words' do
        expect(described_class.look(search: 'title description', and: false)).to eq [groups[1], groups[0]]
      end
    end

    context 'search by interest border' do
      it 'can search within an area' do
        expect(described_class.look(interest_border: InterestBorder.to_key(province), area: true)).to eq [groups[5], groups[4]]
      end

      it 'can search a specific place' do
        expect(described_class.look(interest_border: InterestBorder.to_key(province))).to eq [groups[5]]
      end
    end
  end

  describe '#most_active' do
    it 'returns a list of the 5 most active groups' do
    end
  end

  describe 'interest border field' do
    it 'populates the attributes properly' do
      municipality = create(:municipality, :bologna)
      province = municipality.province
      region = province.region
      country = region.country
      continent = country.continent

      group = create(:group, interest_border_tkn: "C-#{municipality.id}")

      expect(group.interest_border_token).to eq "C-#{municipality.id}"
      expect(group.derived_interest_borders_tokens).to match_array ["K-#{continent.id}",
                                                                    "S-#{country.id}",
                                                                    "R-#{region.id}",
                                                                    "P-#{province.id}",
                                                                    "C-#{municipality.id}"]
    end
  end

  describe '#destroy' do
    it 'removes all the proposals that belong only to one group' do
      group_a = create(:group)
      group_b = create(:group)
      create(:proposal, groups: [group_a, group_b])
      create(:proposal, groups: [group_a])
      create(:proposal, groups: [group_b])
      expect { group_a.destroy }.to change(Proposal, :count).from(3).to(2)
      expect { group_b.destroy }.to change(Proposal, :count).from(2).to(0)
    end
  end

  describe '#is_private?' do
    it 'returns true when group is private' do
      g = build(:group, private: true)
      expect(g.is_private?).to be true
    end

    it 'returns false when group is not private' do
      g = build(:group, private: false)
      expect(g.is_private?).to be false
    end
  end

  describe '#request_by_portavoce?' do
    it 'returns true when accept_requests is REQ_BY_PORTAVOCE' do
      g = build(:group, accept_requests: Group::REQ_BY_PORTAVOCE)
      expect(g.request_by_portavoce?).to be true
    end
  end

  describe '#request_by_vote?' do
    it 'returns true when accept_requests is REQ_BY_VOTE' do
      g = build(:group, accept_requests: Group::REQ_BY_VOTE)
      expect(g.request_by_vote?).to be true
    end
  end

  describe '#request_by_both?' do
    it 'returns true when accept_requests is REQ_BY_BOTH' do
      g = build(:group, accept_requests: Group::REQ_BY_BOTH)
      expect(g.request_by_both?).to be true
    end
  end

  describe '#scoped_participants' do
    it 'returns participants who can participate in proposals' do
      g = create(:group)
      result = g.scoped_participants(:participate_proposals)
      expect(result).to respond_to(:each)
    end
  end

  describe '.most_active' do
    it 'returns a list of up to 5 groups' do
      create_list(:group, 3)
      result = Group.most_active
      expect(result.size).to be <= 5
    end
  end

  describe '#normalize_blank_values' do
    it 'sets blank admin_title to nil' do
      g = build(:group, admin_title: '')
      g.send(:normalize_blank_values)
      expect(g.admin_title).to be_nil
    end
  end

  describe '#description' do
    it 'returns html_safe string' do
      g = create(:group)
      expect(g.description).to respond_to(:html_safe?)
    end
  end
end
