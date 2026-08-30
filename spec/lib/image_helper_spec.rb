require 'rails_helper'

RSpec.describe ImageHelper do
  describe '#group_image_tag' do
    it 'escapes the group name in the alt attribute' do
      malicious_name = %q{"><script>alert(1)</script>}
      group = Struct.new(:image, :name).new(double(attached?: false), malicious_name)
      group.extend(described_class)

      result = group.group_image_tag
      fragment = Nokogiri::HTML.fragment(result)

      expect(fragment.css('script')).to be_empty
      expect(fragment.at_css('img')['alt']).to eq(malicious_name)
      expect(result).not_to include('<script>')
      expect(result).to be_html_safe
    end
  end
end
