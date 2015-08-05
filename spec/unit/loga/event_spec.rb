require 'spec_helper'

RSpec.describe Loga::Event do
  describe 'initialize' do
    let(:options) { {} }

    context 'when initialized with an empty hash' do
      it 'accepts an optional hash' do
        expect(described_class.new(options)).to be_a(Loga::Event)
      end
    end

    context 'when initialized with a hash including a message' do
      let(:message) {  double(:message) }
      let(:options) {  { message: message } }

      before { allow(message).to receive(:to_s) }

      it 'calls to_s on the message' do
        expect(message).to receive(:to_s)
        described_class.new(options)
      end
    end
  end
end
