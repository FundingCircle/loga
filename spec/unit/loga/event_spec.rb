require 'spec_helper'

RSpec.describe Loga::Event do
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

  describe '#to_s' do
    let(:opts) { { message: 'Hello World' } }
    subject { described_class.new(opts) }

    context 'when exception' do
      let(:exception) do
        instance_double(StandardError, to_s: 'Some Message', backtrace: ['file'])
      end
      let(:opts) { super().merge(exception: exception) }
      it 'outputs the message with exception' do
        expect(subject.to_s).to eql("Hello World\nSome Message\nfile")
      end
    end

    context 'when no exception' do
      it 'outputs the message' do
        expect(subject.to_s).to eql('Hello World')
      end
    end
  end

  describe '#inspect' do
    subject { described_class.new message: 'Hey Siri' }

    it 'aliases to to_s' do
      expect(subject.to_s).to eql(subject.inspect)
    end
  end
end
