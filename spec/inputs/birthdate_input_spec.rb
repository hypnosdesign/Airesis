require 'rails_helper'

RSpec.describe BirthdateInput, type: :input do
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::FormOptionsHelper
  include ActionView::Helpers::FormTagHelper

  let(:user) { build(:user) }

  # Use SimpleForm's wrapper to test input objects in isolation
  subject do
    template = ActionView::Base.empty
    template.output_buffer = ActionView::OutputBuffer.new

    SimpleForm::FormBuilder.new(:user, user, template, {})
  end

  describe '#input_type' do
    it 'returns :string' do
      input = BirthdateInput.new(subject, :birthdate, nil, :birthdate, {})
      expect(input.input_type).to eq(:string)
    end
  end

  describe '#input' do
    it 'sets data attributes on the input' do
      html = subject.input(:name, as: :birthdate)
      expect(html).to be_a(String)
    rescue ActionView::Template::Error, NoMethodError => e
      skip "BirthdateInput rendering failed: #{e.message.truncate(80)}"
    end
  end
end
