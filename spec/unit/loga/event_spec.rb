require 'spec_helper'

RSpec.describe Loga::Event, timecop: true do
  describe 'initialize' do
    context 'no message is passed' do
      it 'sets message to an empty string' do
        expect(subject.message).to eq ''
      end
    end

    context 'message is passed' do
      let(:message) { "stuff \xC2".force_encoding 'ASCII-8BIT' }
      let(:subject) { described_class.new message: message }

      it 'sanitizes the input to be UTF-8 convertable' do
        expect(subject.message.to_json).to eq '"stuff ?"'
      end
    end
  end
end
