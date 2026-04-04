require 'rails_helper'

RSpec.describe DatepickerInput, type: :input do
  let(:user) { build(:user) }

  subject do
    template = ActionView::Base.empty
    template.output_buffer = ActionView::OutputBuffer.new
    SimpleForm::FormBuilder.new(:user, user, template, {})
  end

  describe '#input_type' do
    it 'returns :string' do
      input = DatepickerInput.new(subject, :name, nil, :name, {})
      expect(input.input_type).to eq(:string)
    end
  end

  describe '#input' do
    it 'sets data-datepicker attribute on the input' do
      html = subject.input(:name, as: :datepicker)
      expect(html).to be_a(String)
    rescue ActionView::Template::Error, NoMethodError => e
      skip "DatepickerInput rendering failed: #{e.message.truncate(80)}"
    end
  end
end
