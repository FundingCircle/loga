require 'spec_helper'

describe Loga::Configuration do
  describe 'initialize' do
    context 'defaults' do
      specify { expect(subject.host).to eq(hostname_anchor) }
      specify { expect(subject.level).to eq(Logger::INFO) }
      specify { expect(subject.device).to eq(STDOUT) }
      specify { expect(subject.filter_parameters).to eq([]) }
      specify { expect(subject.service_name).to eq(nil) }
      specify { expect(subject.service_version).to eq(nil) }
    end

    context 'when hostname cannot be resolved' do
      before do
        allow(Socket).to receive(:gethostname).and_raise(Exception)
      end

      it 'uses a default hostname' do
        expect(subject.host).to eq('unknown.host')
      end
    end
  end

  describe '#initialize!' do
    subject do
      described_class.new.tap do |config|
        config.service_name    = ' hello_world_app '
        config.service_version =  " 1.0\n"
      end
    end

    it 'initializes the formatter with stiped service name and version' do
      expect(Loga::Formatter).to receive(:new)
        .with(service_name: 'hello_world_app',
              service_version: '1.0',
              host: hostname_anchor)
      subject.initialize!
    end
  end

  describe '#logger' do
    context 'when initialized' do
      before { subject.initialize! }
      it 'returns a logger' do
        expect(subject.logger).to be_a(Logger)
      end

      it 'returns a tagged logger' do
        expect(subject.logger).to respond_to(:tagged)
      end
    end

    context 'when not initialized' do
      specify { expect(subject.logger).to be_nil }
    end
  end

  describe '#configure' do
    it 'yields self' do
      expect { |b| subject.configure(&b) }.to yield_with_args(subject)
    end
  end
end
