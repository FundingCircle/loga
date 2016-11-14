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

  describe '#to_s' do
    let(:opts) { { message: 'Hello World', timestamp: Time.now } }
    subject { described_class.new(opts) }

    context 'when exception' do
      let(:exception) do
        instance_double(StandardError, to_s: 'Some Message', backtrace: ['file'])
      end
      let(:opts) { super().merge(exception: exception) }
      it 'outputs the message with exception' do
        expect(subject.to_s)
          .to eql("#{time_anchor.iso8601(3)} Hello World\nSome Message\nfile")
      end
    end

    context 'when no exception' do
      it 'outputs the message' do
        expect(subject.to_s).to eql("#{time_anchor.iso8601(3)} Hello World")
      end
    end

    context 'when no timestamp' do
      let(:opts) { { message: 'Hello World' } }

      it 'will render the message without it' do
        expect(subject.to_s).to eql('Hello World')
      end
    end
  end

  describe '#inspect' do
    subject { described_class.new message: 'Hey Siri', timestamp: Time.now }

    it 'aliases to to_s' do
      expect(subject.to_s).to eql(subject.inspect)
    end
  end
end
