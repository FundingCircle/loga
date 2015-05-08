require 'spec_helper'

describe ServiceLogger::GELFUPDLogDevice do
  subject { described_class.new }

  describe '#write(message)' do
    context 'when the message in bytes is > maximu chunk size' do
      let(:max_chunk_size) { 1420 }
      let(:message)        { 'A' * max_chunk_size + 'B' * max_chunk_size }

      subject { super().write(message) }

      pending 'sends the message in chunks'
      it 'returns the message in chunks' do
        expect(subject.size).to eq(2)
      end
    end
  end
end
