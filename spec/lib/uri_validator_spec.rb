require 'rails_helper'
require 'uri_validator'

RSpec.describe UriValidator do
  # Use a simple model with a URI attribute to trigger the validator
  let(:model_class) do
    Class.new do
      include ActiveModel::Validations
      attr_accessor :website

      validates :website, uri: true

      def self.name
        'TestModel'
      end
    end
  end

  let(:model) { model_class.new }

  describe '#validate_each' do
    context 'when the URL is invalid format' do
      it 'adds an error for a non-URL string' do
        model.website = 'not-a-url'
        model.valid?
        expect(model.errors[:website]).to include('is invalid or not responding')
      end

      it 'adds an error for nil value' do
        model.website = nil
        model.valid?
        expect(model.errors[:website]).not_to be_empty
      end
    end

    context 'when the URL has valid format' do
      it 'adds an error when the URL does not respond' do
        allow(Net::HTTP).to receive(:get_response).and_raise(SocketError.new('DNS failure'))
        model.website = 'http://nonexistent.example.invalid'
        model.valid?
        expect(model.errors[:website]).to include('is invalid or not responding')
      end

      it 'is valid when the URL returns HTTP success' do
        response_double = instance_double(Net::HTTPSuccess)
        allow(response_double).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Net::HTTP).to receive(:get_response).and_return(response_double)

        # Use case/when with Net::HTTPSuccess pattern
        allow(Net::HTTP).to receive(:get_response) do
          Net::HTTPSuccess.new('1.1', '200', 'OK')
        end

        model.website = 'http://example.com'
        model.valid?
        expect(model.errors[:website]).to be_empty
      end

      it 'adds an error when the URL returns a non-success response' do
        allow(Net::HTTP).to receive(:get_response).and_return(
          Net::HTTPNotFound.new('1.1', '404', 'Not Found')
        )
        model.website = 'http://example.com/not-found'
        model.valid?
        expect(model.errors[:website]).to include('is invalid or not responding')
      end
    end

    context 'with :format option' do
      let(:model_with_format) do
        Class.new do
          include ActiveModel::Validations
          attr_accessor :website

          validates :website, uri: { format: /\Ahttps:\/\// }

          def self.name
            'TestModelWithFormat'
          end
        end
      end

      it 'uses the custom format regex' do
        model = model_with_format.new
        model.website = 'http://example.com'
        model.valid?
        expect(model.errors[:website]).not_to be_empty
      end

      it 'raises ArgumentError when :format is not a Regexp' do
        expect do
          Class.new do
            include ActiveModel::Validations
            attr_accessor :website
            validates :website, uri: { format: 'not-a-regexp' }
            def self.name; 'Bad'; end
          end.new.valid?
        end.to raise_error(ArgumentError)
      end
    end
  end
end
