require 'spec_helper'

describe Loga::GELFUPDLogDevice do
  subject { described_class.new }

  let(:host) { '127.0.0.1' }
  let(:port) { 12_201 }

  describe '#initialize' do
    context 'defaults' do
      specify { expect(subject.host).to eq(host) }
      specify { expect(subject.port).to eq(port) }
      specify { expect(subject.max_chunk_size).to eq(1420) }
      specify { expect(subject.compress).to eq(true) }
    end
  end

  describe '#write(message)' do
    let(:socket) { double :socket, send: nil }

    before do
      allow(subject).to receive(:socket).and_return(socket)
    end

    context 'when the message in bytes is < max_chunk_size' do
      let(:message) { 'Short Message' }

      context 'and compression is disabled' do
        subject { described_class.new(compress: false) }

        it 'sends the message uncompressed' do
          expect(socket).to receive(:send).with(message, 0, host, port).once
          subject.write(message)
        end
      end

      context 'and compression is enabled' do
        let(:message_compressed) { Zlib::Deflate.deflate(message) }

        it 'sends the message compressed' do
          expect(socket).to receive(:send).with(message_compressed, 0, host, port).once
          subject.write(message)
        end
      end
    end

    context 'when the message in bytes is > maximu chunk size' do
      let(:message_part_1) { 'A' * subject.max_chunk_size }
      let(:message_part_2) { 'B' * subject.max_chunk_size }
      let(:message)        { message_part_1 + message_part_2 }

      context 'and compression is disabled' do
        subject { described_class.new(compress: false) }

        it 'sends the message in uncompressed chunks' do
          expect(socket)
            .to receive(:send)
            .with(/#{message_part_1}/, 0, host, port)
            .ordered

          expect(socket)
            .to receive(:send)
            .with(/#{message_part_2}/, 0, host, port)
            .ordered

          subject.write(message)
        end
      end

      pending 'and compression is enabled'
    end
  end
end
